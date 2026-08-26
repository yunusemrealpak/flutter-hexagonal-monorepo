import 'package:core_kernel/core_kernel.dart';

import 'delivery_attempt.dart';
import 'delivery_failure.dart';

/// The operation's record of what its couriers did at the door.
///
/// A driven port. It speaks in attempts, never in requests: there is no URL,
/// no header and no status code in this file, and there cannot be —
/// `delivery_application`, which consumes it, may not depend on `platform/*`
/// at all.
///
/// **[submit] is not called by the use case that completes an attempt.** A
/// courier who has just handed over a parcel is not made to wait for a server,
/// so `CompleteWithProof` queues a `CompleteDeliveryCommand` through
/// `SyncFacade` and returns. What eventually calls this is the transport
/// handler the composition root registered for that command's routing key.
/// The port lives here because the *contract* is delivery's — what an attempt
/// looks like on the wire is this feature's word — while when to call it is
/// the queue's business.
///
/// The identifier on [attemptsFor] arrives raw, like every driven port's: an
/// adapter may see no foreign `_api`, so a signature naming `ShipmentId`
/// would be one its own adapter could not implement.
abstract interface class DeliveryGateway {
  /// Publishes a settled attempt.
  ///
  /// Takes the whole attempt rather than a patch. The entity has already
  /// decided what the visit became; sending "what changed" would make the far
  /// side re-derive a decision this side already made, and the two would
  /// eventually disagree.
  Future<Result<DeliveryAttempt, DeliveryFailure>> submit(
    DeliveryAttempt attempt,
  );

  /// Every attempt recorded against one shipment, oldest first.
  ///
  /// A list rather than the latest one. "Nobody home on Tuesday, delivered on
  /// Wednesday" is two rows, and an operation asked about a complaint needs
  /// both.
  Future<Result<List<DeliveryAttempt>, DeliveryFailure>> attemptsFor(
    String shipmentId,
  );
}
