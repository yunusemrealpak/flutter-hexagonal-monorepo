import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';
import 'package:shipments_api/shipments_api.dart';

import '../../entities/payment_attempt.dart';
import '../../entities/settlement.dart';
import '../../failures/payments_failure.dart';
import '../../values/idempotency_key.dart';
import '../../values/money.dart';
import '../../values/payment_method.dart';
import '../../values/payment_status.dart';

/// What the rest of the product asks payments to do.
///
/// Four intentions, and the first of them is the one the whole feature is
/// shaped around: taking money at a door, over a connection that may not be
/// there, without ever taking it twice.
///
/// A driving port, so its parameters are typed identities — `ShipmentId`,
/// `ActorId` — where a driven port would take raw strings.
///
/// [collectOnDelivery] does not take an idempotency key. That is deliberate: a
/// caller that supplied one would be deciding what counts as *the same
/// intention*, and a screen that regenerated it on rebuild would charge twice.
/// The use case mints the key once, binds it to the shipment, and finds it
/// again on every retry.
abstract interface class PaymentsFacade {
  /// Takes [amount] against [shipment], or returns what a previous attempt at
  /// the same intention produced.
  Future<Result<PaymentAttempt, PaymentsFailure>> collectOnDelivery({
    required ShipmentId shipment,
    required ActorId courier,
    required Money amount,
    required PaymentMethod method,
  });

  /// Gives back what was taken under [key].
  Future<Result<PaymentAttempt, PaymentsFailure>> refund(IdempotencyKey key);

  /// Hands in [courier]'s money for [day].
  Future<Result<Settlement, PaymentsFailure>> closeDailySettlement({
    required ActorId courier,
    required DateTime day,
  });

  /// What is owed on [shipment].
  Future<Result<PaymentStatus, PaymentsFailure>> paymentStatusOf(
    ShipmentId shipment,
  );

  /// Emits an attempt whenever one moves.
  Stream<PaymentAttempt> changes();
}
