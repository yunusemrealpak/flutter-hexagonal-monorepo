import 'package:core_kernel/core_kernel.dart';
import 'package:payments_api/payments_api.dart';

/// A `CashDrawerPort` that really keeps a running total.
///
/// It refuses to release more than it holds, through `Money.minus` — the same
/// rule that refuses a negative amount anywhere else. A fake that let the
/// balance go negative would hide a caller giving back money it never took.
final class FakeCashDrawer implements CashDrawerPort {
  /// Creates a drawer holding [balance].
  FakeCashDrawer(this._balance);

  Money _balance;
  final List<PaymentsFailure> _queuedFailures = [];

  /// Every amount accepted, oldest first.
  final List<Money> accepted = [];

  /// Every amount released, oldest first.
  final List<Money> released = [];

  /// Makes the next call return [failure].
  void failNextWith(PaymentsFailure failure) => _queuedFailures.add(failure);

  @override
  Future<Result<void, PaymentsFailure>> accept(Money amount) async {
    final failure = _takeFailure();
    if (failure != null) return Failed(failure);

    return _balance.plus(amount).map((total) {
      _balance = total;
      accepted.add(amount);
    });
  }

  @override
  Future<Result<void, PaymentsFailure>> release(Money amount) async {
    final failure = _takeFailure();
    if (failure != null) return Failed(failure);

    return _balance.minus(amount).map((total) {
      _balance = total;
      released.add(amount);
    });
  }

  @override
  Future<Result<Money, PaymentsFailure>> balance() async {
    final failure = _takeFailure();
    if (failure != null) return Failed(failure);

    return Success(_balance);
  }

  PaymentsFailure? _takeFailure() =>
      _queuedFailures.isEmpty ? null : _queuedFailures.removeAt(0);
}
