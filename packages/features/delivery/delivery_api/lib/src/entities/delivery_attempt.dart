import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';
import 'package:shipments_api/shipments_api.dart';

import '../failures/delivery_failure.dart';
import '../values/attempt_outcome.dart';
import '../values/delivery_attempt_id.dart';
import '../values/delivery_grade.dart';
import '../values/non_delivery_reason.dart';
import '../values/proof_of_delivery.dart';
import '../values/proof_policy.dart';
import '../values/proof_reference.dart';

/// One visit to one address, and how it went.
///
/// An `Entity`: equality is by [id], because an attempt that has been settled
/// is still the same visit. Attempts are never edited after they settle — the
/// second call is refused rather than applied — so an afternoon's record is
/// something a dispute can be argued from.
///
/// **The rules live here, not in a use case.** Two of them:
///
/// *An attempt settles once.* [completeWith] and [failWith] both refuse an
/// outcome that is already final, which is what stops a double tap on a slow
/// screen becoming two deliveries and a queued retry becoming a second one.
///
/// *A completion is checked against the grade's policy.* [completeWith] asks
/// `ProofPolicy` before it accepts anything, so a high-value parcel closed
/// with a scrawl and no photograph is refused no matter who asked — the
/// courier's screen, a sync drain replaying a queued attempt, a test.
///
/// A use case checks the policy too, before it pays to store the evidence.
/// That is not a duplicated rule: the use case checks to avoid a write it will
/// refuse, and the entity checks because an entity that trusts its caller is
/// not a guardian of anything.
///
/// [shipment] and [courier] are identifiers from two other features and are
/// the only foreign types on this class. What is *not* here is a `Shipment`,
/// an `AddressPoint` or a `ShipmentSummary`: delivery is told a
/// [DeliveryGrade] in its own words and needs nothing else about the parcel.
final class DeliveryAttempt extends Entity<DeliveryAttemptId> {
  const DeliveryAttempt._({
    required super.id,
    required this.shipment,
    required this.courier,
    required this.grade,
    required this.startedAt,
    required this.outcome,
    this.settledAt,
  });

  /// Opens an attempt at the door.
  ///
  /// A plain constructor rather than a validating factory returning a
  /// `Result`: every argument is already a validated value, so there is no way
  /// for this to fail and a failure branch here would be unreachable at every
  /// call site. What *can* refuse a start — the courier being three streets
  /// away — is a question for `GeoFencePort`, which the use case asks before
  /// it gets here.
  factory DeliveryAttempt.started({
    required DeliveryAttemptId id,
    required ShipmentId shipment,
    required ActorId courier,
    required DateTime startedAt,
    DeliveryGrade grade = DeliveryGrade.standard,
  }) => DeliveryAttempt._(
    id: id,
    shipment: shipment,
    courier: courier,
    grade: grade,
    startedAt: startedAt.toUtc(),
    outcome: const AttemptOutcome.inProgress(),
  );

  /// Which parcel.
  final ShipmentId shipment;

  /// Who is at the door.
  final ActorId courier;

  /// How much proof this parcel is worth.
  final DeliveryGrade grade;

  /// When the courier arrived, in UTC.
  final DateTime startedAt;

  /// How it went, or that it has not gone yet.
  final AttemptOutcome outcome;

  /// When it stopped being in progress, in UTC, or `null` while it still is.
  final DateTime? settledAt;

  /// Whether this attempt is finished with.
  bool get isSettled => outcome.isSettled;

  /// The handle the stored evidence is known by, or `null` when there is none.
  ///
  /// The one piece of a completed attempt the rest of the product is allowed
  /// to see. `ShipmentStatus.deliveredToConsignee` takes it, so does
  /// `DeliveryCompleted`, and the signature it points at never leaves this
  /// feature.
  ProofReference? get proofReference => switch (outcome) {
    AttemptCompleted(:final reference) => reference,
    AttemptInProgress() || AttemptFailed() => null,
  };

  /// Closes the attempt with the evidence that was captured.
  ///
  /// [reference] is where the evidence was stored, which the use case has
  /// because it asked `ProofStorePort` first. The order matters: a proof that
  /// the policy will refuse is never written down, and a proof that was
  /// written down is always on a settled attempt.
  Result<DeliveryAttempt, DeliveryFailure> completeWith({
    required ProofOfDelivery proof,
    required ProofReference reference,
    required DateTime at,
  }) {
    if (isSettled) return Failed(AttemptAlreadySettled(id.value));

    return ProofPolicy.forGrade(grade)
        .accept(proof)
        .map(
          (accepted) => _settled(
            AttemptOutcome.completed(proof: accepted, reference: reference),
            at,
          ),
        );
  }

  /// Closes the attempt without a hand-over.
  ///
  /// No policy runs: a visit that did not end in a delivery has no evidence to
  /// be sufficient. What it has is a reason, and `NonDeliveryReason` has
  /// already refused the ones that carry nothing usable.
  Result<DeliveryAttempt, DeliveryFailure> failWith({
    required NonDeliveryReason reason,
    required DateTime at,
  }) {
    if (isSettled) return Failed(AttemptAlreadySettled(id.value));
    return Success(_settled(AttemptOutcome.failed(reason), at));
  }

  DeliveryAttempt _settled(AttemptOutcome next, DateTime at) =>
      DeliveryAttempt._(
        id: id,
        shipment: shipment,
        courier: courier,
        grade: grade,
        startedAt: startedAt,
        outcome: next,
        settledAt: at.toUtc(),
      );

  @override
  String toString() =>
      'DeliveryAttempt(${id.value}, ${shipment.value}, $outcome)';
}
