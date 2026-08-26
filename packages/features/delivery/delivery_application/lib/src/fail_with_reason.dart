import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:delivery_api/delivery_api.dart';
import 'package:sync_api/sync_api.dart';

import 'fail_delivery_command.dart';

/// What a caller wants closed, and why it did not happen.
typedef FailRequest = ({DeliveryAttempt attempt, NonDeliveryReason reason});

/// Closes an attempt without a hand-over.
///
/// Shorter than its sibling by four steps, and every one of the missing steps
/// is missing for the same reason: there is no evidence. Nothing to check
/// against a policy, nothing to compress, nothing to store, no reference to
/// carry. What there is, is a reason — and `NonDeliveryReason` has already
/// refused the ones that carry nothing a person could act on.
///
/// **No domain event is published.** Not an oversight: nothing in the product
/// subscribes to a failed delivery yet, and an event published for a listener
/// that does not exist is a guess about the future that later has to be
/// honoured. The write still reaches the server through the queue, which is
/// where a failed visit actually matters — a dispatcher reassigning tomorrow's
/// round reads it from there.
final class FailWithReason
    implements UseCase<FailRequest, Result<DeliveryAttempt, DeliveryFailure>> {
  /// Creates the use case.
  const FailWithReason({required this._sync, required this._clock});

  final SyncFacade _sync;
  final Clock _clock;

  @override
  Future<Result<DeliveryAttempt, DeliveryFailure>> call(
    FailRequest request,
  ) async {
    final DeliveryAttempt settled;
    switch (request.attempt.failWith(
      reason: request.reason,
      at: _clock.now(),
    )) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        settled = value;
    }

    final queued = await _sync.enqueue(FailDeliveryCommand(settled));
    if (queued case Failed(:final failure)) {
      return Failed(DeliveryUnavailable(detail: '$failure'));
    }

    return Success(settled);
  }
}
