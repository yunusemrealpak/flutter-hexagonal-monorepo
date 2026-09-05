import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:payments_api/payments_api.dart';

/// Keeps a running total of what the courier is holding.
///
/// A courier's "drawer" is a pouch, so the adapter is a number on the device
/// rather than a hardware contract. What it is *for* is the end of a shift: the
/// amount here is compared with the amount in the settlement, and a difference
/// is a fact somebody has to explain rather than an error this adapter should
/// judge.
///
/// **The arithmetic goes through `Money`**, which is what stops the balance
/// going negative: releasing more than is held fails on `Money.minus`, by the
/// same rule that refuses a negative collection anywhere else. An adapter with
/// an `if` of its own would be a second place for that rule to drift.
///
/// The total is stored as minor units and a currency code, never as a decimal
/// string. A drawer rebuilt from a parsed double is off by an amount somebody
/// has to explain at exactly the moment they are trying to hand in cash.
final class KeyValueCashDrawer implements CashDrawerPort {
  /// Creates the adapter over [store], counting in [currency].
  const KeyValueCashDrawer({
    required this.store,
    this.currency = Currency.tryLira,
    this.namespace = 'payments.drawer',
  });

  /// Where the total goes.
  final KeyValueStore store;

  /// What the courier is holding.
  ///
  /// One currency per drawer. A courier carrying two would need two drawers,
  /// which is what a `Money` that refuses to add across currencies is telling
  /// you.
  final Currency currency;

  /// The key prefix this adapter owns.
  final String namespace;

  @override
  Future<Result<void, PaymentsFailure>> accept(Money amount) =>
      _change((balance) => balance.plus(amount));

  @override
  Future<Result<void, PaymentsFailure>> release(Money amount) =>
      _change((balance) => balance.minus(amount));

  @override
  Future<Result<Money, PaymentsFailure>> balance() async {
    final String? raw;
    switch (await store.read('$namespace.$currency')) {
      case Failed(:final failure):
        return Failed(CashDrawerUnavailable(detail: '$failure'));
      case Success(:final value):
        raw = value;
    }

    // An empty drawer is what a shift starts with, not a failure.
    return Money.of(
      minorUnits: int.tryParse(raw ?? '0') ?? 0,
      currency: currency,
    );
  }

  Future<Result<void, PaymentsFailure>> _change(
    Result<Money, PaymentsFailure> Function(Money) apply,
  ) async {
    final Money current;
    switch (await balance()) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        current = value;
    }

    final Money next;
    switch (apply(current)) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        next = value;
    }

    return switch (await store.write(
      '$namespace.$currency',
      '${next.minorUnits}',
    )) {
      Failed(:final failure) => Failed(
        CashDrawerUnavailable(detail: '$failure'),
      ),
      Success() => const Success(null),
    };
  }
}
