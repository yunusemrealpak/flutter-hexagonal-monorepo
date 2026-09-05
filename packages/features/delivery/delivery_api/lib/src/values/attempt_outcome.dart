import 'package:freezed_annotation/freezed_annotation.dart';

import 'non_delivery_reason.dart';
import 'proof_of_delivery.dart';
import 'proof_reference.dart';

part 'attempt_outcome.freezed.dart';

/// How a visit ended, or that it has not ended yet.
///
/// Three states that carry different things, which is why this is a union and
/// not a pair of nullable fields on the attempt. An attempt in progress has
/// neither a proof nor a reason; a completed one has both a proof and the
/// reference it was stored under; a failed one has a reason and nothing else.
/// Flattened onto the entity, that is four nullable fields and eight
/// combinations, six of which are nonsense.
///
/// [AttemptCompleted] carries the proof *and* its reference. The reference is
/// what the rest of the product sees and the proof is what delivery keeps, and
/// an attempt that had only the reference could not be re-examined without a
/// round trip to a store — which on a courier's device may be the one thing
/// that is not reachable.
@freezed
sealed class AttemptOutcome with _$AttemptOutcome {
  const AttemptOutcome._();

  /// The courier is at the door.
  const factory AttemptOutcome.inProgress() = AttemptInProgress;

  /// Handed over, with the evidence and where it was put.
  const factory AttemptOutcome.completed({
    required ProofOfDelivery proof,
    required ProofReference reference,
  }) = AttemptCompleted;

  /// Attempted and not handed over.
  const factory AttemptOutcome.failed(NonDeliveryReason reason) = AttemptFailed;

  /// Whether this outcome is final.
  ///
  /// The guard behind `DeliveryFailure.attemptAlreadySettled`: an attempt is
  /// settled once, and the second tap on a slow screen is refused by the
  /// domain rather than by whichever adapter remembered to disable a button.
  bool get isSettled => switch (this) {
    AttemptInProgress() => false,
    AttemptCompleted() || AttemptFailed() => true,
  };
}
