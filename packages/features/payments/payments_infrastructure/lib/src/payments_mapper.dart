import 'package:core_kernel/core_kernel.dart';
import 'package:payments_api/payments_api.dart';

import 'payments_dto.dart';

/// Translates between the payments domain and the shapes that cross a wire or
/// a disk.
///
/// Hand-written, like every mapper in this workspace, and it does two things a
/// generated one would still have to be told.
///
/// **An attempt is read back by replaying its transitions.** A stored one is
/// built as an intention and then taken, refused or refunded, exactly as it
/// happened — so no shape this mapper produces is one the domain could not
/// have produced. A refund that arrived without a taking fails here rather
/// than becoming a hole in a settlement.
///
/// **A settlement is not replayed**, because its totals are an aggregate;
/// `Settlement.restored` takes them as they were stored. The guard for that is
/// in `runSettlementStoreContract`, which asserts a store reads the totals
/// back rather than the identifier alone.
///
/// **This file imports no foreign feature**, and not by luck: section 2
/// forbids `feature_infrastructure` from reaching another feature at all,
/// contract included. Rebuilding the `ActorId` and `ShipmentId` payments' own
/// contract is expressed in goes through `CourierReference` and
/// `ShipmentReference` in `payments_api`, which is the one layer allowed to
/// see them.
abstract final class PaymentsMapper {
  /// Turns an attempt into the shape the wire and the device both use.
  static PaymentAttemptDto attemptToDto(PaymentAttempt attempt) {
    final method = attempt.request.method;

    return PaymentAttemptDto(
      idempotencyKey: attempt.id.value,
      shipmentId: attempt.request.shipment.value,
      courierId: attempt.request.courier.value,
      minorUnits: attempt.amount.minorUnits,
      currency: attempt.amount.currency.code,
      method: switch (method) {
        Cash() => 'cash',
        Card() => 'card',
        Transfer() => 'transfer',
      },
      last4: switch (method) {
        Card(:final last4) => last4,
        _ => null,
      },
      transferReference: switch (method) {
        Transfer(:final reference) => reference,
        _ => null,
      },
      outcome: switch (attempt.outcome) {
        PaymentPending() => 'pending',
        PaymentTaken() => 'taken',
        PaymentRefused() => 'refused',
        PaymentRefunded() => 'refunded',
      },
      takenAt: switch (attempt.outcome) {
        PaymentTaken(:final at) => at.toUtc().toIso8601String(),
        PaymentRefunded(:final takenAt) => takenAt.toUtc().toIso8601String(),
        _ => null,
      },
      refundedAt: switch (attempt.outcome) {
        PaymentRefunded(:final refundedAt) =>
          refundedAt.toUtc().toIso8601String(),
        _ => null,
      },
      refusalReason: switch (attempt.outcome) {
        PaymentRefused(:final reason) => reason,
        _ => null,
      },
    );
  }

  /// Reads an attempt back, by replaying how it got where it is.
  static Result<PaymentAttempt, PaymentsFailure> attemptToDomain(
    PaymentAttemptDto dto,
  ) {
    final IdempotencyKey key;
    switch (IdempotencyKey.parse(dto.idempotencyKey ?? '')) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        key = value;
    }

    final Money amount;
    switch (_money(dto.minorUnits, dto.currency, 'attempt.amount')) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        amount = value;
    }

    final PaymentMethod method;
    switch (_method(dto)) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        method = value;
    }

    // Chained with flatMap rather than bound to locals, because a local would
    // have to be *declared* — `final ShipmentId shipment;` — and writing that
    // type name is the one thing this file must not do.
    final shipmentRead = ShipmentReference.parse(dto.shipmentId ?? '');
    if (shipmentRead case Failed(:final failure)) return Failed(failure);

    final courierRead = CourierReference.parse(dto.courierId ?? '');
    if (courierRead case Failed(:final failure)) return Failed(failure);

    return shipmentRead.flatMap(
      (shipment) => courierRead.flatMap((courier) {
        final intending = PaymentAttempt.intending(
          key: key,
          request: CollectionRequest(
            shipment: shipment,
            courier: courier,
            amount: amount,
            method: method,
          ),
        );

        return switch (dto.outcome) {
          'pending' || null => Success(intending),
          'refused' => intending.refused(reason: dto.refusalReason ?? ''),
          'taken' => _instant(
            dto.takenAt,
            'attempt.takenAt',
          ).flatMap((at) => intending.taken(at: at)),
          'refunded' => _refunded(intending, dto),
          _ => Failed(
            MalformedPaymentValue(
              field: 'attempt.outcome',
              reason: '${dto.outcome} is not an outcome',
            ),
          ),
        };
      }),
    );
  }

  /// Turns a day into the shape a store keeps.
  static SettlementDto settlementToDto(Settlement settlement) => SettlementDto(
    id: settlement.id.value,
    courierId: settlement.courier.value,
    day: settlement.day.toUtc().toIso8601String(),
    currency: settlement.collected.currency.code,
    collectedMinorUnits: settlement.collected.minorUnits,
    refundedMinorUnits: settlement.refunded.minorUnits,
    closedAt: settlement.closedAt?.toUtc().toIso8601String(),
  );

  /// Reads a day back.
  static Result<Settlement, PaymentsFailure> settlementToDomain(
    SettlementDto dto,
  ) {
    final SettlementId id;
    switch (SettlementId.parse(dto.id ?? '')) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        id = value;
    }

    final DateTime day;
    switch (_instant(dto.day, 'settlement.day')) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        day = value;
    }

    final Money collected;
    switch (_money(
      dto.collectedMinorUnits,
      dto.currency,
      'settlement.collected',
    )) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        collected = value;
    }

    final Money refunded;
    switch (_money(
      dto.refundedMinorUnits,
      dto.currency,
      'settlement.refunded',
    )) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        refunded = value;
    }

    DateTime? closedAt;
    if (dto.closedAt != null) {
      switch (_instant(dto.closedAt, 'settlement.closedAt')) {
        case Failed(:final failure):
          return Failed(failure);
        case Success(:final value):
          closedAt = value;
      }
    }

    return CourierReference.parse(dto.courierId ?? '').map(
      (courier) => Settlement.restored(
        id: id,
        courier: courier,
        day: day,
        collected: collected,
        refunded: refunded,
        closedAt: closedAt,
      ),
    );
  }

  static Result<PaymentAttempt, PaymentsFailure> _refunded(
    PaymentAttempt intending,
    PaymentAttemptDto dto,
  ) => _instant(dto.takenAt, 'attempt.takenAt')
      .flatMap((takenAt) => intending.taken(at: takenAt))
      .flatMap(
        (taken) => _instant(
          dto.refundedAt,
          'attempt.refundedAt',
        ).flatMap((at) => taken.refunded(at: at)),
      );

  static Result<PaymentMethod, PaymentsFailure> _method(
    PaymentAttemptDto dto,
  ) => switch (dto.method) {
    'cash' => const Success(PaymentMethod.cash()),
    'card' =>
      dto.last4 == null
          ? const Failed(
              MalformedPaymentValue(
                field: 'attempt.last4',
                reason: 'a card arrived without its last four digits',
              ),
            )
          : Success(PaymentMethod.card(last4: dto.last4!)),
    'transfer' =>
      dto.transferReference == null
          ? const Failed(
              MalformedPaymentValue(
                field: 'attempt.transferReference',
                reason: 'a transfer arrived without its reference',
              ),
            )
          : Success(PaymentMethod.transfer(reference: dto.transferReference!)),
    _ => Failed(
      MalformedPaymentValue(
        field: 'attempt.method',
        reason: '${dto.method} is not a method',
      ),
    ),
  };

  static Result<Money, PaymentsFailure> _money(
    int? minorUnits,
    String? code,
    String field,
  ) {
    if (minorUnits == null) {
      return Failed(
        MalformedPaymentValue(field: field, reason: 'has no amount'),
      );
    }

    final currency = Currency.fromCode(code ?? '');
    if (currency == null) {
      return Failed(
        MalformedPaymentValue(
          field: field,
          reason: '$code is not a currency this operation takes',
        ),
      );
    }

    return Money.of(minorUnits: minorUnits, currency: currency);
  }

  static Result<DateTime, PaymentsFailure> _instant(String? raw, String field) {
    if (raw == null) {
      return Failed(MalformedPaymentValue(field: field, reason: 'is absent'));
    }

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return Failed(
        MalformedPaymentValue(field: field, reason: '$raw is not an instant'),
      );
    }
    return Success(parsed.toUtc());
  }
}
