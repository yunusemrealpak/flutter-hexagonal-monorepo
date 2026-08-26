import 'dart:convert';

import 'package:core_kernel/core_kernel.dart';
import 'package:delivery_api/delivery_api.dart';

import 'delivery_dto.dart';

/// Translates between the delivery domain and the shapes that cross a wire or
/// a disk.
///
/// Hand-written, like every mapper in this workspace. What a generated one
/// would still have to be told is exactly what is in this file: that an absent
/// field is a named failure rather than a `TypeError`, that instants go out in
/// UTC, and that a value object gets to refuse its own input.
///
/// **Reading an attempt back walks the domain's own transitions.** There is no
/// hydrating constructor on `DeliveryAttempt`: a stored one is rebuilt by
/// starting it and then completing or failing it, exactly as it happened the
/// first time. That costs a few lines and buys the guarantee that no shape
/// this mapper produces is a shape the domain could not have produced —
/// including the policy check, so a stored high-value proof that has lost its
/// photograph fails to load instead of quietly becoming a valid delivery.
///
/// **This file imports no foreign feature**, and that is not an accident of
/// what it happens to need. Section 2 forbids `feature_infrastructure` from
/// reaching another feature at all, contract included — so rebuilding the
/// `ActorId` and `ShipmentId` that delivery's own contract is expressed in
/// goes through `CourierReference` and `ShipmentReference` in `delivery_api`,
/// which is the one layer allowed to see them.
///
/// Every read is written as a `switch` that binds or returns. The shorter
/// spelling — `fold((v) => v, (_) => throw …)` — puts a throw on a branch the
/// author believes is unreachable, and a mapper is precisely the place where
/// that belief is being tested by somebody else's data.
abstract final class DeliveryMapper {
  /// Turns a proof into the shape both stores use.
  static ProofDto proofToDto(ProofOfDelivery proof) => ProofDto(
    recipientName: proof.recipient.name,
    recipientRelationship: proof.recipient.relationship,
    capturedAt: proof.capturedAt.toUtc().toIso8601String(),
    signatureBase64: _encode(proof.signature?.bytes),
    signatureCapturedAt: proof.signature?.capturedAt.toUtc().toIso8601String(),
    photoBase64: _encode(proof.photo?.bytes),
    photoMimeType: proof.photo?.mimeType,
    photoCapturedAt: proof.photo?.capturedAt.toUtc().toIso8601String(),
    scanSymbol: proof.scan?.symbol,
    scanAt: proof.scan?.scannedAt.toUtc().toIso8601String(),
  );

  /// Reads a proof back.
  static Result<ProofOfDelivery, DeliveryFailure> proofToDomain(ProofDto dto) {
    final Recipient recipient;
    switch (Recipient.named(
      dto.recipientName ?? '',
      relationship: dto.recipientRelationship ?? 'self',
    )) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        recipient = value;
    }

    final DateTime capturedAt;
    switch (_instant(dto.capturedAt, 'proof.capturedAt')) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        capturedAt = value;
    }

    SignatureCapture? signature;
    if (dto.signatureBase64 != null) {
      switch (_signature(dto, capturedAt)) {
        case Failed(:final failure):
          return Failed(failure);
        case Success(:final value):
          signature = value;
      }
    }

    PhotoEvidence? photo;
    if (dto.photoBase64 != null) {
      switch (_photo(dto, capturedAt)) {
        case Failed(:final failure):
          return Failed(failure);
        case Success(:final value):
          photo = value;
      }
    }

    ScanEvidence? scan;
    final symbol = dto.scanSymbol;
    if (symbol != null) {
      final at = _instant(dto.scanAt, 'proof.scanAt', fallback: capturedAt);
      switch (at.flatMap(
        (when) => ScanEvidence.of(symbol: symbol, scannedAt: when),
      )) {
        case Failed(:final failure):
          return Failed(failure);
        case Success(:final value):
          scan = value;
      }
    }

    return Success(
      ProofOfDelivery.captured(
        recipient: recipient,
        capturedAt: capturedAt,
        signature: signature,
        photo: photo,
        scan: scan,
      ),
    );
  }

  /// Turns an attempt into the shape the operation's record uses.
  static DeliveryAttemptDto attemptToDto(DeliveryAttempt attempt) {
    final outcome = attempt.outcome;

    return DeliveryAttemptDto(
      id: attempt.id.value,
      shipmentId: attempt.shipment.value,
      courierId: attempt.courier.value,
      grade: attempt.grade.name,
      startedAt: attempt.startedAt.toUtc().toIso8601String(),
      settledAt: attempt.settledAt?.toUtc().toIso8601String(),
      outcome: switch (outcome) {
        AttemptInProgress() => 'inProgress',
        AttemptCompleted() => 'completed',
        AttemptFailed() => 'failed',
      },
      proofReference: attempt.proofReference?.value,
      proof: switch (outcome) {
        AttemptCompleted(:final proof) => proofToDto(proof),
        AttemptInProgress() || AttemptFailed() => null,
      },
      reason: switch (outcome) {
        AttemptFailed(:final reason) => _reasonTag(reason),
        AttemptInProgress() || AttemptCompleted() => null,
      },
      reasonNote: switch (outcome) {
        AttemptFailed(:final reason) => _reasonNote(reason),
        AttemptInProgress() || AttemptCompleted() => null,
      },
      reasonRequestedFor: switch (outcome) {
        AttemptFailed(reason: Rescheduled(:final requestedFor)) =>
          requestedFor.toUtc().toIso8601String(),
        _ => null,
      },
    );
  }

  /// Reads an attempt back, by replaying how it got where it is.
  static Result<DeliveryAttempt, DeliveryFailure> attemptToDomain(
    DeliveryAttemptDto dto,
  ) {
    final DeliveryAttemptId id;
    switch (DeliveryAttemptId.parse(dto.id ?? '')) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        id = value;
    }

    // Chained with flatMap rather than bound to locals, because a local would
    // have to be *declared* — `final ShipmentId shipment;` — and writing that
    // type name is the one thing this file must not do. The lambda's parameter
    // type is inferred, which is the difference between not naming a type and
    // not depending on it.
    final shipmentRead = ShipmentReference.parse(dto.shipmentId ?? '');
    if (shipmentRead case Failed(:final failure)) return Failed(failure);

    final courierRead = CourierReference.parse(dto.courierId ?? '');
    if (courierRead case Failed(:final failure)) return Failed(failure);

    final DateTime startedAt;
    switch (_instant(dto.startedAt, 'attempt.startedAt')) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        startedAt = value;
    }

    return shipmentRead.flatMap(
      (shipment) => courierRead.flatMap((courier) {
        final started = DeliveryAttempt.started(
          id: id,
          shipment: shipment,
          courier: courier,
          startedAt: startedAt,
          grade: _grade(dto.grade),
        );

        return switch (dto.outcome) {
          'inProgress' || null => Success(started),
          'completed' => _complete(started, dto),
          'failed' => _fail(started, dto),
          _ => Failed(
            MalformedDeliveryValue(
              field: 'attempt.outcome',
              reason: '${dto.outcome} is not an outcome',
            ),
          ),
        };
      }),
    );
  }

  static Result<DeliveryAttempt, DeliveryFailure> _complete(
    DeliveryAttempt started,
    DeliveryAttemptDto dto,
  ) {
    final proofDto = dto.proof;
    if (proofDto == null) {
      return const Failed(
        MalformedDeliveryValue(
          field: 'attempt.proof',
          reason: 'a completed attempt arrived without its evidence',
        ),
      );
    }

    final ProofReference reference;
    switch (ProofReference.parse(dto.proofReference ?? '')) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        reference = value;
    }

    final DateTime settledAt;
    switch (_instant(dto.settledAt, 'attempt.settledAt')) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        settledAt = value;
    }

    return proofToDomain(proofDto).flatMap(
      (proof) => started.completeWith(
        proof: proof,
        reference: reference,
        at: settledAt,
      ),
    );
  }

  static Result<DeliveryAttempt, DeliveryFailure> _fail(
    DeliveryAttempt started,
    DeliveryAttemptDto dto,
  ) {
    final DateTime settledAt;
    switch (_instant(dto.settledAt, 'attempt.settledAt')) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        settledAt = value;
    }

    return _reason(dto).flatMap(
      (reason) => started.failWith(reason: reason, at: settledAt),
    );
  }

  static Result<NonDeliveryReason, DeliveryFailure> _reason(
    DeliveryAttemptDto dto,
  ) => switch (dto.reason) {
    'recipientAbsent' => const Success(NonDeliveryReason.recipientAbsent()),
    'addressNotFound' => Success(
      NonDeliveryReason.addressNotFound(found: dto.reasonNote),
    ),
    'refusedByRecipient' => Success(
      NonDeliveryReason.refusedByRecipient(note: dto.reasonNote),
    ),
    'damagedInTransit' =>
      dto.reasonNote == null
          // The one case whose note is required. "Damaged" with nothing
          // after it is not something anybody can act on months later, and
          // the domain says so — a mapper that invented one would overrule it.
          ? const Failed(
              MalformedDeliveryValue(
                field: 'attempt.reasonNote',
                reason: 'damage was recorded without a note',
              ),
            )
          : Success(NonDeliveryReason.damagedInTransit(note: dto.reasonNote!)),
    'accessDenied' => Success(
      NonDeliveryReason.accessDenied(note: dto.reasonNote),
    ),
    'rescheduled' => _instant(
      dto.reasonRequestedFor,
      'attempt.reasonRequestedFor',
    ).map((at) => NonDeliveryReason.rescheduled(requestedFor: at)),
    _ => Failed(
      MalformedDeliveryValue(
        field: 'attempt.reason',
        reason: '${dto.reason} is not a reason',
      ),
    ),
  };

  /// Reads the target a geofence measures against.
  static Result<
    ({double latitude, double longitude, double allowedMetres}),
    DeliveryFailure
  >
  targetToDomain(GeoTargetDto dto) {
    final latitude = dto.latitude;
    final longitude = dto.longitude;
    if (latitude == null || longitude == null) {
      return const Failed(
        MalformedDeliveryValue(
          field: 'target',
          reason: 'the address has no coordinates',
        ),
      );
    }

    return Success((
      latitude: latitude,
      longitude: longitude,
      // A default rather than a failure: an operation that has not configured
      // a radius still has couriers at doors, and refusing every delivery
      // until somebody sets a number is worse than measuring against a
      // reasonable one.
      allowedMetres: dto.allowedMetres ?? 100,
    ));
  }

  static String _reasonTag(NonDeliveryReason reason) => switch (reason) {
    RecipientAbsent() => 'recipientAbsent',
    AddressNotFound() => 'addressNotFound',
    RefusedByRecipient() => 'refusedByRecipient',
    DamagedInTransit() => 'damagedInTransit',
    AccessDenied() => 'accessDenied',
    Rescheduled() => 'rescheduled',
  };

  static String? _reasonNote(NonDeliveryReason reason) => switch (reason) {
    AddressNotFound(:final found) => found,
    RefusedByRecipient(:final note) => note,
    DamagedInTransit(:final note) => note,
    AccessDenied(:final note) => note,
    RecipientAbsent() || Rescheduled() => null,
  };

  static DeliveryGrade _grade(String? raw) => switch (raw) {
    'highValue' => DeliveryGrade.highValue,
    // An unreadable grade reads as standard rather than failing. Getting a
    // grade wrong loosens a proof requirement; refusing to load the record
    // loses the delivery. The first is recoverable, the second is not.
    _ => DeliveryGrade.standard,
  };

  static Result<SignatureCapture, DeliveryFailure> _signature(
    ProofDto dto,
    DateTime fallback,
  ) => _bytes(dto.signatureBase64, 'proof.signatureBase64').flatMap(
    (bytes) =>
        _instant(
          dto.signatureCapturedAt,
          'proof.signatureCapturedAt',
          fallback: fallback,
        ).flatMap(
          (at) => SignatureCapture.of(bytes: bytes, capturedAt: at),
        ),
  );

  static Result<PhotoEvidence, DeliveryFailure> _photo(
    ProofDto dto,
    DateTime fallback,
  ) => _bytes(dto.photoBase64, 'proof.photoBase64').flatMap(
    (bytes) =>
        _instant(
          dto.photoCapturedAt,
          'proof.photoCapturedAt',
          fallback: fallback,
        ).flatMap(
          (at) => PhotoEvidence.of(
            bytes: bytes,
            capturedAt: at,
            mimeType: dto.photoMimeType ?? 'image/jpeg',
          ),
        ),
  );

  static String? _encode(List<int>? bytes) =>
      bytes == null ? null : base64Encode(bytes);

  static Result<List<int>, DeliveryFailure> _bytes(String? raw, String field) {
    if (raw == null) {
      return Failed(
        MalformedDeliveryValue(field: field, reason: 'is absent'),
      );
    }
    try {
      return Success(base64Decode(raw));
    } on FormatException catch (error) {
      // The one place in this package that catches. A decoder throws and a
      // port may not, so the exception stops here and becomes a failure —
      // invariant 1.2.9, at the boundary it was written for.
      return Failed(
        MalformedDeliveryValue(field: field, reason: error.message),
      );
    }
  }

  static Result<DateTime, DeliveryFailure> _instant(
    String? raw,
    String field, {
    DateTime? fallback,
  }) {
    if (raw == null) {
      if (fallback != null) return Success(fallback);
      return Failed(
        MalformedDeliveryValue(field: field, reason: 'is absent'),
      );
    }

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return Failed(
        MalformedDeliveryValue(field: field, reason: '$raw is not an instant'),
      );
    }
    return Success(parsed.toUtc());
  }
}
