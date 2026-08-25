import 'package:core_kernel/core_kernel.dart';
import 'package:shipments_api/shipments_api.dart';

import 'shipment_dto.dart';

/// Translates between the wire and the domain, in both directions.
///
/// Hand-written, and that is the point of it. A generator can turn JSON into a
/// data class; it cannot decide that an absent `barcode` is
/// `MalformedBarcode` rather than a `TypeError`, or that a status object whose
/// `kind` nobody recognises is a failure with the unknown value quoted in it.
/// Those are decisions, and this file is where the workspace keeps them.
///
/// It is also the enforcement point for invariant 1.2.10. Nothing above this
/// file ever sees a `ShipmentDto`, and nothing below it ever sees a
/// `Shipment`. Deleting this file and passing DTOs upwards would compile and
/// would put `snake_case` and nullable everything into the state machine.
abstract final class ShipmentMapper {
  /// Builds a domain shipment from what arrived.
  ///
  /// Returns a `Result` because every step of it can fail on input the far
  /// side is free to send. The failures name the field, because "malformed
  /// shipment" on its own is the kind of message that sends somebody to a
  /// packet capture.
  static Result<Shipment, ShipmentFailure> toDomain(ShipmentDto dto) {
    final id = dto.id;
    if (id == null) {
      return const Failed(MalformedValue(field: 'id', reason: 'is absent'));
    }
    final barcode = dto.barcode;
    if (barcode == null) {
      return const Failed(
        MalformedValue(field: 'barcode', reason: 'is absent'),
      );
    }
    final consigneeDto = dto.consignee;
    if (consigneeDto == null) {
      return const Failed(
        MalformedValue(field: 'consignee', reason: 'is absent'),
      );
    }
    final statusDto = dto.status;
    if (statusDto == null) {
      return const Failed(MalformedValue(field: 'status', reason: 'is absent'));
    }

    return ShipmentId.parse(id).flatMap(
      (shipmentId) => Barcode.parse(barcode).flatMap(
        (parsedBarcode) => _consignee(consigneeDto).flatMap(
          (consignee) => _status(statusDto).flatMap(
            (status) => _history(dto.history ?? const []).map(
              (history) => Shipment(
                id: shipmentId,
                barcode: parsedBarcode,
                consignee: consignee,
                status: status,
                history: history,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a manifest row from what arrived.
  static Result<ShipmentSummary, ShipmentFailure> summaryToDomain(
    ShipmentSummaryDto dto,
  ) {
    final id = dto.id;
    final barcode = dto.barcode;
    final statusDto = dto.status;
    if (id == null || barcode == null || statusDto == null) {
      return const Failed(
        MalformedValue(field: 'summary', reason: 'is missing a required field'),
      );
    }

    return _status(statusDto).map(
      (status) => ShipmentSummary(
        id: id,
        barcode: barcode,
        status: status,
        consigneeName: dto.consigneeName ?? '',
        address: dto.address ?? '',
      ),
    );
  }

  /// Writes a domain shipment back to the wire.
  ///
  /// Total, unlike [toDomain]: a `Shipment` cannot be invalid, because the
  /// only ways to obtain one are a validating factory and a transition the
  /// state machine allowed. That asymmetry is what a boundary looks like when
  /// it is doing its job.
  static ShipmentDto toDto(Shipment shipment) => ShipmentDto(
    id: shipment.id.value,
    barcode: shipment.barcode.value,
    status: statusToDto(shipment.status),
    consignee: ConsigneeDto(
      name: shipment.consignee.name,
      phone: shipment.consignee.phone,
      address: AddressDto(
        formatted: shipment.consignee.address.formatted,
        latitude: shipment.consignee.address.latitude,
        longitude: shipment.consignee.address.longitude,
      ),
    ),
    history: shipment.history
        .map(
          (move) => StatusTransitionDto(
            from: statusToDto(move.from),
            to: statusToDto(move.to),
            at: move.at.toIso8601String(),
            by: move.by?.value,
          ),
        )
        .toList(),
  );

  /// Writes a status back to the wire.
  static ShipmentStatusDto statusToDto(ShipmentStatus status) =>
      switch (status) {
        ShipmentAwaitingAssignment() => ShipmentStatusDto(kind: status.label),
        ShipmentAssignedToCourier(:final courier) => ShipmentStatusDto(
          kind: status.label,
          courier: courier.value,
        ),
        ShipmentLoadedOnVehicle(:final courier) => ShipmentStatusDto(
          kind: status.label,
          courier: courier.value,
        ),
        ShipmentOutForDelivery(:final courier) => ShipmentStatusDto(
          kind: status.label,
          courier: courier.value,
        ),
        ShipmentDeliveredToConsignee(:final proofReference, :final at) =>
          ShipmentStatusDto(
            kind: status.label,
            proofReference: proofReference,
            at: at.toIso8601String(),
          ),
        ShipmentUndeliverable(:final reason, :final at) => ShipmentStatusDto(
          kind: status.label,
          reason: reason,
          at: at.toIso8601String(),
        ),
        ShipmentReturnedToDepot(:final at) => ShipmentStatusDto(
          kind: status.label,
          at: at.toIso8601String(),
        ),
      };

  static const MalformedValue _courierAbsent = MalformedValue(
    field: 'status.courier',
    reason: 'is absent on a state that has one',
  );

  static Result<Consignee, ShipmentFailure> _consignee(ConsigneeDto dto) {
    final addressDto = dto.address;
    if (addressDto == null) {
      return const Failed(
        MalformedValue(field: 'consignee.address', reason: 'is absent'),
      );
    }
    return AddressPoint.create(
      formatted: addressDto.formatted ?? '',
      latitude: addressDto.latitude,
      longitude: addressDto.longitude,
    ).flatMap(
      (address) => Consignee.create(
        name: dto.name ?? '',
        address: address,
        phone: dto.phone,
      ),
    );
  }

  static Result<ShipmentStatus, ShipmentFailure> _status(
    ShipmentStatusDto dto,
  ) {
    final kind = dto.kind;
    return switch (kind) {
      'awaitingAssignment' => const Success(
        ShipmentStatus.awaitingAssignment(),
      ),
      // The courier is read through CourierReference in shipments_api, not
      // through identity's own parser, and it is written inline rather than
      // pulled into a helper. This package may not depend on a foreign _api,
      // so a helper would need a return type it cannot name; inline, the type
      // stays inferred and the rule stays enforced by the compiler.
      'assignedToCourier' => switch (dto.courier) {
        null => const Failed(_courierAbsent),
        final raw => CourierReference.parse(
          raw,
        ).map(ShipmentStatus.assignedToCourier),
      },
      'loadedOnVehicle' => switch (dto.courier) {
        null => const Failed(_courierAbsent),
        final raw => CourierReference.parse(
          raw,
        ).map(ShipmentStatus.loadedOnVehicle),
      },
      'outForDelivery' => switch (dto.courier) {
        null => const Failed(_courierAbsent),
        final raw => CourierReference.parse(
          raw,
        ).map(ShipmentStatus.outForDelivery),
      },
      'deliveredToConsignee' => _moment(dto.at, 'status.at').flatMap(
        (at) => dto.proofReference == null
            ? const Failed<ShipmentStatus, ShipmentFailure>(
                MalformedValue(
                  field: 'status.proofReference',
                  reason: 'is absent on a delivered shipment',
                ),
              )
            : Success(
                ShipmentStatus.deliveredToConsignee(
                  proofReference: dto.proofReference!,
                  at: at,
                ),
              ),
      ),
      'undeliverable' => _moment(dto.at, 'status.at').flatMap(
        (at) => dto.reason == null
            ? const Failed<ShipmentStatus, ShipmentFailure>(
                MalformedValue(
                  field: 'status.reason',
                  reason: 'is absent on an undelivered shipment',
                ),
              )
            : Success(
                ShipmentStatus.undeliverable(reason: dto.reason!, at: at),
              ),
      ),
      'returnedToDepot' => _moment(
        dto.at,
        'status.at',
      ).map((at) => ShipmentStatus.returnedToDepot(at: at)),
      // A state this build does not know about. Guessing — falling back to
      // "awaiting assignment", say — would put a parcel that the operation has
      // already delivered back at the top of somebody's manifest.
      _ => Failed(
        MalformedValue(
          field: 'status.kind',
          reason: 'unknown state ${kind ?? 'null'}',
        ),
      ),
    };
  }

  static Result<List<StatusTransition>, ShipmentFailure> _history(
    List<StatusTransitionDto> rows,
  ) {
    final moves = <StatusTransition>[];
    for (final row in rows) {
      final from = row.from;
      final to = row.to;
      if (from == null || to == null) {
        return const Failed(
          MalformedValue(field: 'history', reason: 'a move is missing a state'),
        );
      }
      // `by` goes through the same helper as the courier on a state, for
      // the same reason: this package may not depend on identity_api, and
      // what it needs is shipments' reading of a courier reference rather
      // than identity's.
      final built = _status(from).flatMap(
        (fromStatus) => _status(to).flatMap(
          (toStatus) => _moment(row.at, 'history.at').flatMap(
            (at) => CourierReference.parseOptional(row.by).map(
              (actor) => StatusTransition(
                from: fromStatus,
                to: toStatus,
                at: at,
                by: actor,
              ),
            ),
          ),
        ),
      );
      switch (built) {
        case Failed(:final failure):
          return Failed(failure);
        case Success(:final value):
          moves.add(value);
      }
    }
    return Success(moves);
  }

  static Result<DateTime, ShipmentFailure> _moment(String? raw, String field) {
    if (raw == null) {
      return Failed(MalformedValue(field: field, reason: 'is absent'));
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return Failed(
        MalformedValue(field: field, reason: 'is not an ISO-8601 instant'),
      );
    }
    // UTC, always. The Clock port promises UTC, and a local DateTime compared
    // against one is off by whatever the device's offset happens to be — a bug
    // that only shows up for users in the wrong timezone.
    return Success(parsed.toUtc());
  }
}
