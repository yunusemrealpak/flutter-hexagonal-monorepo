import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';
import 'package:shipments_api/shipments_api.dart';

import 'delivery_attempt.dart';
import 'delivery_failure.dart';
import 'delivery_grade.dart';
import 'non_delivery_reason.dart';
import 'proof_of_delivery.dart';

/// What the rest of the product asks delivery to do.
///
/// Three intentions and one read, and they match the shape of a courier's
/// afternoon: arrive, hand over or explain why not, and be able to answer what
/// happened later.
///
/// A driving port, so its parameters are *typed* identities — `ShipmentId`,
/// `ActorId` — where a driven port would take raw strings. The asymmetry is
/// deliberate and it is written down in CLAUDE.md section 10: a driving port
/// is called by code that is allowed to see other features, and a driven port
/// is implemented by an adapter that is not.
///
/// [completeWithProof] and [failWithReason] take the attempt itself rather
/// than its identifier. The caller has it — it is what [startAttempt]
/// returned — and passing it back means delivery does not need a journal port
/// to look up something the screen was already holding.
abstract interface class DeliveryFacade {
  /// Opens an attempt at [shipment]'s address.
  ///
  /// Refuses when the courier is not there: the geofence is asked first, and
  /// an attempt started from three streets away is `OutsideDeliveryArea`
  /// rather than a record nobody can trust. `grade` is delivery's own word for
  /// how much proof the parcel is worth, supplied by whoever knows what is in
  /// it.
  Future<Result<DeliveryAttempt, DeliveryFailure>> startAttempt({
    required ShipmentId shipment,
    required ActorId courier,
    DeliveryGrade grade = DeliveryGrade.standard,
  });

  /// Closes [attempt] with the evidence the courier captured.
  ///
  /// The evidence is stored, the attempt is settled, the write is queued and
  /// `DeliveryCompleted` is published — in that order, and the courier is not
  /// made to wait for a server at any point in it.
  Future<Result<DeliveryAttempt, DeliveryFailure>> completeWithProof({
    required DeliveryAttempt attempt,
    required ProofOfDelivery proof,
  });

  /// Closes [attempt] without a hand-over.
  Future<Result<DeliveryAttempt, DeliveryFailure>> failWithReason({
    required DeliveryAttempt attempt,
    required NonDeliveryReason reason,
  });

  /// Every attempt recorded against [shipment], oldest first.
  Future<Result<List<DeliveryAttempt>, DeliveryFailure>> attemptsFor(
    ShipmentId shipment,
  );

  /// Emits an attempt whenever one settles.
  Stream<DeliveryAttempt> changes();
}
