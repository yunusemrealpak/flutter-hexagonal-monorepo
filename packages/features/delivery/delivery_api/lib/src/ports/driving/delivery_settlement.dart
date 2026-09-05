import 'package:core_kernel/core_kernel.dart';

import '../../entities/delivery_attempt.dart';
import '../../failures/delivery_failure.dart';
import '../../values/non_delivery_reason.dart';
import '../../values/proof_of_delivery.dart';

/// Closing an attempt, with or without a hand-over.
///
/// **Both audiences perform this**, which is why `ProofPolicy` is documented
/// as holding for "the courier's screen, the dispatcher's correction and the
/// sync drain replaying a queued attempt" alike. The ports behind it are a
/// proof store, a compressor and the sync queue — none of them asks where the
/// caller is standing, so a desk can answer all of them.
///
/// Both methods take the attempt itself rather than its identifier. The caller
/// has it — it is what `DeliveryExecution.startAttempt` returned, or what
/// `DeliveryHistory.attemptsFor` read back — and passing it back means
/// delivery does not need a journal port to look up something the screen was
/// already holding.
abstract interface class DeliverySettlement {
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
}
