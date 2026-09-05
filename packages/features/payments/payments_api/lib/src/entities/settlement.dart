import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';

import '../failures/payments_failure.dart';
import '../values/money.dart';
import '../values/payment_outcome.dart';
import '../values/settlement_id.dart';
import 'payment_attempt.dart';

/// One courier's money for one day.
///
/// An `Entity`: equality is by [id], which is derived from the courier and the
/// date. A courier has exactly one settlement per day, so two devices that
/// computed the identifier independently agree — the opposite of
/// `IdempotencyKey`, where deriving would be a collision waiting to happen.
///
/// **Only cash is counted.** A card payment settles between an acquirer and a
/// bank and never passes through anybody's hands; counting it here would ask a
/// courier to hand over money they never held. `PaymentMethod.isCash` is the
/// question, asked once, on the union that knows the answer.
///
/// Closing is one-way. A day that has been handed in and counted is a day
/// somebody signed for, and a settlement that could reopen would let a late
/// collection change a number after the money was counted.
final class Settlement extends Entity<SettlementId> {
  const Settlement._({
    required super.id,
    required this.courier,
    required this.day,
    required this.collected,
    required this.refunded,
    required this.closedAt,
  });

  /// Rebuilds a day that was read back from a store.
  ///
  /// **Unlike `DeliveryAttempt`, a settlement is not replayed.** An attempt is
  /// rebuilt by starting it and then completing it, because everything it took
  /// to get there is in the record. A settlement's totals are an *aggregate*:
  /// replaying them would mean reading every attempt of the day back out of
  /// somewhere, which is precisely what storing the total was for.
  ///
  /// So this factory takes the numbers as they were stored, and the guard is
  /// somewhere else — `runSettlementStoreContract` asserts that a store reads
  /// back the totals rather than the identifier alone. An adapter that dropped
  /// them fails there rather than silently opening every morning at zero.
  ///
  /// [day] is normalised to midnight UTC, like `openFor`, so a stored instant
  /// that kept a time of day does not produce a second settlement for the same
  /// date.
  factory Settlement.restored({
    required SettlementId id,
    required ActorId courier,
    required DateTime day,
    required Money collected,
    required Money refunded,
    DateTime? closedAt,
  }) {
    final utc = day.toUtc();
    return Settlement._(
      id: id,
      courier: courier,
      day: DateTime.utc(utc.year, utc.month, utc.day),
      collected: collected,
      refunded: refunded,
      closedAt: closedAt?.toUtc(),
    );
  }

  /// Opens an empty day for [courier].
  static Result<Settlement, PaymentsFailure> openFor({
    required ActorId courier,
    required DateTime day,
    required Money zero,
  }) => SettlementId.forDay(courier.value, day).map(
    (id) => Settlement._(
      id: id,
      courier: courier,
      day: DateTime.utc(day.toUtc().year, day.toUtc().month, day.toUtc().day),
      collected: zero,
      refunded: zero,
      closedAt: null,
    ),
  );

  /// Whose day it is.
  final ActorId courier;

  /// Which day, at midnight UTC.
  final DateTime day;

  /// The cash taken.
  final Money collected;

  /// The cash given back.
  final Money refunded;

  /// When the day was handed in, or `null` while it is still open.
  final DateTime? closedAt;

  /// Whether this day still accepts collections.
  bool get isOpen => closedAt == null;

  /// What the courier owes the depot.
  Result<Money, PaymentsFailure> get owed => collected.minus(refunded);

  /// Adds a settled attempt to the day.
  ///
  /// Ignores anything that is not cash and anything that did not settle, which
  /// is why a caller can hand it every attempt of the day without filtering
  /// first — and why the filter cannot drift between callers.
  Result<Settlement, PaymentsFailure> including(PaymentAttempt attempt) {
    if (!isOpen) return Failed(SettlementClosed(id.value));
    if (!attempt.request.method.isCash) return Success(this);

    return switch (attempt.outcome) {
      PaymentTaken() =>
        collected.plus(attempt.amount).map((total) => _with(collected: total)),
      PaymentRefunded() =>
        collected
            .plus(attempt.amount)
            .flatMap(
              (total) => refunded
                  .plus(attempt.amount)
                  .map((back) => _with(collected: total, refunded: back)),
            ),
      PaymentPending() || PaymentRefused() => Success(this),
    };
  }

  /// Hands the day in.
  Result<Settlement, PaymentsFailure> close({required DateTime at}) {
    if (!isOpen) return Failed(SettlementClosed(id.value));
    return Success(
      Settlement._(
        id: id,
        courier: courier,
        day: day,
        collected: collected,
        refunded: refunded,
        closedAt: at.toUtc(),
      ),
    );
  }

  Settlement _with({Money? collected, Money? refunded}) => Settlement._(
    id: id,
    courier: courier,
    day: day,
    collected: collected ?? this.collected,
    refunded: refunded ?? this.refunded,
    closedAt: closedAt,
  );

  @override
  String toString() => 'Settlement(${id.value}, $collected)';
}
