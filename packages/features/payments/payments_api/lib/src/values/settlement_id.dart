import 'package:core_kernel/core_kernel.dart';

import '../failures/payments_failure.dart';

/// Identifies one courier's money for one day.
final class SettlementId extends ValueObject<String> {
  const SettlementId._(super.value);

  /// Reads a settlement identifier from [raw].
  static Result<SettlementId, PaymentsFailure> parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const Failed(
        MalformedPaymentValue(field: 'settlementId', reason: 'is empty'),
      );
    }
    return Success(SettlementId._(trimmed));
  }

  /// The identifier for [courierId] on [day].
  ///
  /// Derived rather than minted, and this is the case where deriving is right:
  /// a courier has exactly one settlement per day, so two devices computing
  /// the identifier independently have to agree. That is the opposite of
  /// `IdempotencyKey`, where deriving would collide the day a customer
  /// legitimately paid twice for the same parcel.
  static Result<SettlementId, PaymentsFailure> forDay(
    String courierId,
    DateTime day,
  ) {
    final utc = day.toUtc();
    final month = utc.month.toString().padLeft(2, '0');
    final date = utc.day.toString().padLeft(2, '0');
    return parse('$courierId:${utc.year}-$month-$date');
  }
}
