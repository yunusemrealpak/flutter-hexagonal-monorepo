import 'package:core_kernel/core_kernel.dart';

import 'conflict_policy.dart';
import 'outbox_entry.dart';
import 'outbox_entry_id.dart';
import 'sync_command.dart';
import 'sync_failure.dart';
import 'sync_status.dart';

/// What the rest of the product asks sync to do.
///
/// Four methods, and none of them names a feature. That is the entire
/// interface across which `delivery`, `payments` and `incidents` hand their
/// offline writes to a queue that will never know what they were — scenario 3,
/// at the one place a caller touches it.
///
/// Note what is absent: there is no `send(DeliveryAttempt)`, no
/// `queuePayment`, no per-feature overload. A facade with one method per
/// caller would put every feature's name in this package and invert the arrow
/// the feature depends on.
abstract interface class SyncFacade {
  /// Queues [command] for delivery, under [policy] if the server has moved on.
  ///
  /// Returns the entry that was written, so that the caller has the identifier
  /// — which is also the handle the server de-duplicates on, and therefore the
  /// only thing a feature can later use to ask what became of its write.
  ///
  /// Queueing does not attempt delivery. A use case that called this and then
  /// waited for the network would be an offline-first product that is not.
  ///
  /// [policy] defaults to `lastWriteWins`, which is the one of the three that
  /// cannot lose the device's work: it resends rather than dropping or
  /// blocking. A feature that has not thought about conflicts should get the
  /// option that keeps what the courier did, not the one that discards it.
  Future<Result<OutboxEntry, SyncFailure>> enqueue(
    SyncCommand command, {
    ConflictPolicy policy = const ConflictPolicy.lastWriteWins(),
  });

  /// Attempts every entry that is due, oldest first, and reports where the
  /// queue ended up.
  ///
  /// Called by whatever decides that now is a good moment — a connectivity
  /// change, a foreground transition, a timer in the composition root. It is
  /// not called by the features that enqueue: they have already returned to
  /// the courier by then.
  Future<Result<SyncStatus, SyncFailure>> drain();

  /// The entries a person has to resolve.
  ///
  /// Everything the queue gave up on: permanently rejected work, conflicts
  /// under `ConflictPolicy.manualReview`, and entries that exhausted their
  /// attempts. They are still stored — the evidence of a delivery or a
  /// payment is not something a queue may discard on its own.
  Future<Result<List<OutboxEntry>, SyncFailure>> awaitingReview();

  /// Puts a blocked entry back into the queue after a person resolved it.
  ///
  /// The attempt count is preserved rather than reset, so an entry that has
  /// been round this loop twice is visibly not a fresh one.
  Future<Result<OutboxEntry, SyncFailure>> retry(OutboxEntryId id);

  /// Emits the queue's state whenever it changes.
  ///
  /// Implementations emit the current status on subscription, so a badge that
  /// appears mid-drain does not sit blank until the next transition.
  Stream<SyncStatus> statusChanges();
}
