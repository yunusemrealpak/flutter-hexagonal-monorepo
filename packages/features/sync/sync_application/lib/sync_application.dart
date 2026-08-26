/// The sync use cases: pure Dart, and blind to every adapter that answers its
/// ports — and to every feature whose work it carries.
///
/// `DrainOutbox` is the one worth reading. It is the only place in the
/// workspace that holds a retry policy, and it is a list of decisions rather
/// than a loop:
///
/// - **Offline stops the drain without counting an attempt.** A device in a
///   tunnel would otherwise burn its whole attempt budget in one pass and
///   block a shift's work for manual review because of a lift.
/// - **A store failure stops the drain and is reported.** A queue that cannot
///   be trusted to remember must not be written into.
/// - **A permanent failure blocks one entry; the rest keep draining.**
/// - **A conflict is the entry's `ConflictPolicy`'s decision.** The feature
///   chose it when it queued the work, because whether the device's version
///   outranks the server's is a business question.
///
/// The jitter for every backoff is drawn from the `RandomSource` port and the
/// resulting instant is written onto the entry, which is what makes a queue
/// with exponential backoff testable without waiting for one.
///
/// `SyncCoordinator` implements `SyncFacade` by delegating to the five use
/// cases. It stays thin on purpose: if it ever grows a decision of its own,
/// that is the signal a use case is missing.
library;

export 'src/drain_outbox.dart';
export 'src/enqueue_command.dart';
export 'src/read_sync_status.dart';
export 'src/review_queue.dart';
export 'src/sync_coordinator.dart';
