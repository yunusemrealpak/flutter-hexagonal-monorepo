import 'package:core_kernel/core_kernel.dart';
import 'package:delivery_api/delivery_api.dart';

import 'complete_with_proof.dart';
import 'delivery_channel.dart';
import 'fail_with_reason.dart';

/// `DeliverySettlement`'s implementation: closing an attempt.
///
/// Deliberately thin, like every coordinator in this workspace. What decides
/// anything is behind it — `ProofPolicy` on the entity, the order of the steps
/// in `CompleteWithProof`.
///
/// Its collaborators are a proof store, a compressor, the sync queue and the
/// event bus. Not one of them asks where the caller is standing, which is why
/// both apps compose it.
final class DeliverySettlementCoordinator implements DeliverySettlement {
  /// Creates the coordinator over its use cases.
  DeliverySettlementCoordinator({
    required this._complete,
    required this._fail,
    required this._channel,
  });

  final CompleteWithProof _complete;
  final FailWithReason _fail;
  final DeliveryChannel _channel;

  @override
  Future<Result<DeliveryAttempt, DeliveryFailure>> completeWithProof({
    required DeliveryAttempt attempt,
    required ProofOfDelivery proof,
  }) => _channel.announce(_complete((attempt: attempt, proof: proof)));

  @override
  Future<Result<DeliveryAttempt, DeliveryFailure>> failWithReason({
    required DeliveryAttempt attempt,
    required NonDeliveryReason reason,
  }) => _channel.announce(_fail((attempt: attempt, reason: reason)));
}
