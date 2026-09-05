import 'package:core_kernel/core_kernel.dart';
import 'package:shipments_api/shipments_api.dart';

import '../../failures/payments_failure.dart';
import '../../values/payment_status.dart';

/// Answers what is owed on one parcel, and nothing else.
///
/// **This is payments' half of scenario 1.** `shipments_application` consults
/// it before it lets a delivery close against an outstanding cash collection;
/// `payments_application` consults `shipments_api` for its own reasons. The
/// two `_application` packages never meet — each depends on the other
/// feature's *contract*, and a contract package depends on no implementation,
/// so the graph stays acyclic. `dep_graph` shows it in phase 8.
///
/// Deliberately narrow, for the same reason `SessionReader` is narrower than
/// `IdentityFacade` and `PermissionChecker` is narrower than a permission set.
/// Handing `shipments` the whole `PaymentsFacade` would also hand it the
/// ability to take money, and handing it a `PaymentAttempt` would let it
/// reason about the idempotency key, the courier and the method — things it is
/// not asking about. One question, one answer.
///
/// A driving port, so it takes the typed identity: it is called by code that
/// is allowed to see other features. Compare `PaymentsGateway.attemptFor`,
/// which takes a raw string because an adapter implements it.
abstract interface class PaymentStatusReader {
  /// What is owed on [shipment].
  Future<Result<PaymentStatus, PaymentsFailure>> statusFor(ShipmentId shipment);
}
