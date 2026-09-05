import 'package:freezed_annotation/freezed_annotation.dart';

import 'money.dart';

part 'payment_status.freezed.dart';

/// What another feature is told about the money owed on a parcel.
///
/// **The answer `shipments` gets, and the whole of it.** It is deliberately
/// not a `PaymentAttempt`: handing over the attempt would give a caller the
/// idempotency key, the courier, the method and the ability to reason about
/// things it is not asking about — "they have tried twice, close enough". One
/// question, one answer, which is the same rule `PermissionChecker` follows.
///
/// It carries `Money` and not a raw number, because the currency is part of
/// the answer and "there is 4500 outstanding" is not a sentence anybody can
/// act on without it.
@freezed
sealed class PaymentStatus with _$PaymentStatus {
  const PaymentStatus._();

  /// Nothing is owed on this parcel.
  ///
  /// The ordinary case — most parcels are paid for before they are shipped —
  /// and a state rather than a failure, so that a caller does not have to
  /// treat "prepaid" as an error.
  const factory PaymentStatus.nothingToCollect() = NothingToCollect;

  /// Money is owed and has not been taken.
  const factory PaymentStatus.outstanding(Money amount) = Outstanding;

  /// The money was taken.
  const factory PaymentStatus.settled({
    required Money amount,
    required DateTime at,
  }) = SettledInFull;

  /// It was taken and given back.
  const factory PaymentStatus.refunded({
    required Money amount,
    required DateTime at,
  }) = Refunded;

  /// Whether the operation is still waiting for this money.
  ///
  /// The single question `shipments` actually asks before it lets a delivery
  /// close. Behaviour on the union rather than a `switch` at the call site,
  /// because the call site is in another feature and a copy of this rule over
  /// there would be a copy nobody updates.
  bool get isOutstanding => this is Outstanding;
}
