import 'package:core_kernel/core_kernel.dart';
import 'package:meta/meta.dart';

import '../failures/delivery_failure.dart';
import 'delivery_grade.dart';
import 'evidence_kind.dart';
import 'proof_of_delivery.dart';

/// How much evidence a hand-over needs before it counts.
///
/// **The business rule the specification asks to live in a policy object
/// inside `_api`**, and the placement is the lesson. A rule in a use case is a
/// rule one driving adapter obeys: put "high-value parcels need a signature
/// and a photograph" inside `CompleteWithProof` and the sync drain that
/// replays a queued attempt does not know about it, nor does the dispatcher
/// screen that records a hand-over the office was told about by telephone.
/// Here, everything that can build a completed attempt goes through it,
/// because `DeliveryAttempt.completeWith` asks it first.
///
/// It is a value with no dependencies at all — no clock, no store, no
/// gateway — which is what makes the rule testable as a table and reviewable
/// by somebody who does not read Dart.
@immutable
final class ProofPolicy {
  /// The policy for [grade].
  const ProofPolicy.forGrade(this.grade);

  /// The grade this policy speaks for.
  final DeliveryGrade grade;

  /// The kinds of evidence this grade will not do without.
  ///
  /// Empty for [DeliveryGrade.standard] — which does not mean "nothing is
  /// needed", it means "no *particular* kind is needed". The floor of at least
  /// one piece applies to every grade and is enforced in [accept]; expressing
  /// it here as three alternative sets would say the same thing three times
  /// and get one of them wrong on the day a fourth kind of evidence arrives.
  Set<EvidenceKind> get insistsOn => switch (grade) {
    DeliveryGrade.standard => const {},
    DeliveryGrade.highValue => const {
      EvidenceKind.signature,
      EvidenceKind.photo,
    },
  };

  /// Returns [proof] when it is enough, and says what is missing when it is
  /// not.
  Result<ProofOfDelivery, DeliveryFailure> accept(ProofOfDelivery proof) {
    final carried = proof.carries;

    if (carried.isEmpty) {
      return Failed(
        ProofInsufficient(grade: grade.name, missing: const ['any evidence']),
      );
    }

    final missing = insistsOn.difference(carried);
    if (missing.isNotEmpty) {
      return Failed(
        ProofInsufficient(
          grade: grade.name,
          missing: [for (final kind in missing) kind.name]..sort(),
        ),
      );
    }

    return Success(proof);
  }

  @override
  String toString() => 'ProofPolicy(${grade.name})';
}
