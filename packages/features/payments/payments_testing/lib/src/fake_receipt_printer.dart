import 'package:core_kernel/core_kernel.dart';
import 'package:payments_api/payments_api.dart';

/// A `ReceiptPrinterPort` a test can make fail.
///
/// The failing path is the interesting one, and it is the reason this port
/// exists at all: a receipt that would not print must *not* undo a collection.
/// Money the courier is holding with no record of it is worse than a customer
/// with no slip of paper, and the decision to carry on belongs in a use case
/// rather than in an adapter.
final class FakeReceiptPrinter implements ReceiptPrinterPort {
  /// Every attempt a receipt was asked for, oldest first.
  final List<PaymentAttempt> issued = [];

  final List<PaymentsFailure> _queuedFailures = [];

  /// Makes the next call return [failure].
  void failNextWith(PaymentsFailure failure) => _queuedFailures.add(failure);

  @override
  Future<Result<void, PaymentsFailure>> issue(PaymentAttempt attempt) async {
    final failure = _takeFailure();
    if (failure != null) return Failed(failure);

    issued.add(attempt);
    return const Success(null);
  }

  PaymentsFailure? _takeFailure() =>
      _queuedFailures.isEmpty ? null : _queuedFailures.removeAt(0);
}
