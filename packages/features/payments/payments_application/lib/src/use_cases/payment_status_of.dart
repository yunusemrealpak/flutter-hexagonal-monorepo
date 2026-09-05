import 'package:core_kernel/core_kernel.dart';
import 'package:payments_api/payments_api.dart';
import 'package:shipments_api/shipments_api.dart';

/// Answers what is owed on one parcel.
///
/// **The use case behind scenario 1.** `shipments_application` asks
/// `PaymentStatusReader` before it lets a delivery close, and this is what
/// answers — through a port, from another feature, with neither
/// `_application` package naming the other.
///
/// It turns an attempt into a *status*, which is the narrowing that makes the
/// port worth having. Handing back the attempt would give `shipments` the
/// idempotency key, the courier and the method, and an invitation to reason
/// about things it is not asking about.
///
/// A parcel with no attempt against it is `nothingToCollect`, not a failure.
/// Most parcels are prepaid, and an operation whose shipment screen showed an
/// error for the ordinary case would have taught everybody to ignore it.
final class PaymentStatusOf
    implements UseCase<ShipmentId, Result<PaymentStatus, PaymentsFailure>> {
  /// Creates the use case.
  const PaymentStatusOf({required this._gateway});

  final PaymentsGateway _gateway;

  @override
  Future<Result<PaymentStatus, PaymentsFailure>> call(
    ShipmentId shipment,
  ) async => switch (await _gateway.attemptFor(shipment.value)) {
    Failed(:final failure) => Failed(failure),
    Success(:final value) => Success(_statusOf(value)),
  };

  static PaymentStatus _statusOf(PaymentAttempt? attempt) {
    if (attempt == null) return const PaymentStatus.nothingToCollect();

    return switch (attempt.outcome) {
      // Pending and refused both mean the operation is still waiting for the
      // money, which is the only distinction the asking feature cares about.
      // Why it is still waiting is payments' business.
      PaymentPending() || PaymentRefused() => PaymentStatus.outstanding(
        attempt.amount,
      ),
      PaymentTaken(:final at) => PaymentStatus.settled(
        amount: attempt.amount,
        at: at,
      ),
      PaymentRefunded(:final refundedAt) => PaymentStatus.refunded(
        amount: attempt.amount,
        at: refundedAt,
      ),
    };
  }
}
