import 'package:core_kernel/core_kernel.dart';
import 'package:meta/meta.dart';

import 'currency.dart';
import 'payments_failure.dart';

/// An amount of money, in one currency.
///
/// **Held in minor units as an `int`.** Not a `double`, and this is the one
/// place in the workspace where the type choice is worth an argument: 0.1 +
/// 0.2 is not 0.3 in binary floating point, and a settlement that adds four
/// hundred cash collections in doubles will be off by an amount somebody has
/// to explain. Integers of kuruş are exact, and the only cost is remembering
/// that 1250 is twelve and a half lira.
///
/// **Arithmetic returns a `Result`.** Adding euros to lira has no answer, and
/// any implementation that produced one would be wrong in a way nobody notices
/// until the end of a day. `CurrencyMismatch` is its own failure case for the
/// same reason.
///
/// Negative amounts are refused at construction. A refund is a *direction*
/// rather than a negative amount — `PaymentAttempt.refunded` — and allowing
/// both spellings would mean two ways to say the same thing and two places to
/// get the sign wrong.
@immutable
final class Money {
  const Money._({required this.minorUnits, required this.currency});

  /// Nothing, in [currency].
  ///
  /// A constructor rather than a static method, so that `Money.zero(...)`
  /// reads the way `Money.of(...)` does. It cannot fail — zero is never
  /// negative — which is why it is the one construction in this class that
  /// does not return a `Result`.
  const Money.zero(this.currency) : minorUnits = 0;

  /// Reads an amount, refusing a negative one.
  static Result<Money, PaymentsFailure> of({
    required int minorUnits,
    required Currency currency,
  }) {
    if (minorUnits < 0) {
      return Failed(
        MalformedPaymentValue(
          field: 'money',
          reason: '$minorUnits is negative',
        ),
      );
    }
    return Success(Money._(minorUnits: minorUnits, currency: currency));
  }

  /// How much, in the currency's smallest unit.
  final int minorUnits;

  /// Which currency.
  final Currency currency;

  /// Whether this is nothing.
  bool get isZero => minorUnits == 0;

  /// Adds [other], or refuses when the currencies differ.
  Result<Money, PaymentsFailure> plus(Money other) =>
      _sameCurrencyAs(
        other,
      ).flatMap(
        (_) => Money.of(
          minorUnits: minorUnits + other.minorUnits,
          currency: currency,
        ),
      );

  /// Subtracts [other], refusing a different currency or a negative result.
  ///
  /// The negative check is `Money.of`'s, which is the point of routing every
  /// construction through it: taking more out of a drawer than went in is
  /// refused by the same rule that refuses a negative collection.
  Result<Money, PaymentsFailure> minus(Money other) =>
      _sameCurrencyAs(
        other,
      ).flatMap(
        (_) => Money.of(
          minorUnits: minorUnits - other.minorUnits,
          currency: currency,
        ),
      );

  Result<void, PaymentsFailure> _sameCurrencyAs(Money other) =>
      other.currency == currency
      ? const Success(null)
      : Failed(
          CurrencyMismatch(
            expected: currency.code,
            actual: other.currency.code,
          ),
        );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Money &&
          other.minorUnits == minorUnits &&
          other.currency == currency;

  @override
  int get hashCode => Object.hash(minorUnits, currency);

  @override
  String toString() => '$minorUnits ${currency.code}';
}
