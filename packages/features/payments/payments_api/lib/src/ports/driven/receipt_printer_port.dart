import 'package:core_kernel/core_kernel.dart';

import '../../entities/payment_attempt.dart';
import '../../failures/payments_failure.dart';

/// Gives the customer something to keep.
///
/// A driven port whose failure is deliberately *not* allowed to undo a
/// collection. A receipt that would not print is an inconvenience; a payment
/// rolled back because of one is money the courier is holding and the
/// operation has no record of. `CollectOnDelivery` therefore logs a printing
/// failure and returns success, which is the kind of decision that belongs in
/// a use case rather than in an adapter.
///
/// The port exists at all because "was a receipt produced" is a question an
/// operation is asked by a regulator, and answering it needs a seam that a
/// test can watch.
abstract interface class ReceiptPrinterPort {
  /// Produces a receipt for [attempt].
  Future<Result<void, PaymentsFailure>> issue(PaymentAttempt attempt);
}
