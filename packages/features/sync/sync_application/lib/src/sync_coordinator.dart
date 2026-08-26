import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:sync_api/sync_api.dart';

import 'drain_outbox.dart';
import 'enqueue_command.dart';
import 'read_sync_status.dart';
import 'review_queue.dart';

/// The driving port's implementation: one intention per method, each of them a
/// call into a use case.
///
/// Deliberately thin, like `ShipmentsCoordinator`. Everything that decides
/// anything is behind it — the retry policy in `DrainOutbox`, the state
/// machine of a queued entry in `OutboxEntry`, the status rules in
/// `ReadSyncStatus`. What this class adds is the shape of the port and the
/// status stream, and if it ever grows a rule of its own that is the signal a
/// use case is missing.
///
/// It is not called `SyncFacadeImpl`. The name says what it does rather than
/// which interface it satisfies.
final class SyncCoordinator implements SyncFacade {
  /// Creates the coordinator over its use cases.
  SyncCoordinator({
    required this._enqueue,
    required this._drain,
    required this._readStatus,
    required this._loadReviewQueue,
    required this._resolve,
  });

  final EnqueueCommand _enqueue;
  final DrainOutbox _drain;
  final ReadSyncStatus _readStatus;
  final LoadReviewQueue _loadReviewQueue;
  final ResolveBlockedEntry _resolve;

  final StreamController<SyncStatus> _statuses =
      StreamController<SyncStatus>.broadcast();

  @override
  Future<Result<OutboxEntry, SyncFailure>> enqueue(
    SyncCommand command, {
    ConflictPolicy policy = const ConflictPolicy.lastWriteWins(),
  }) async {
    final queued = await _enqueue((command: command, policy: policy));
    if (queued.isSuccess) await _announce();
    return queued;
  }

  @override
  Future<Result<SyncStatus, SyncFailure>> drain() async {
    final drained = await _drain(());
    if (drained case Success(value: final status)) _statuses.add(status);
    return drained;
  }

  @override
  Future<Result<List<OutboxEntry>, SyncFailure>> awaitingReview() =>
      _loadReviewQueue(());

  @override
  Future<Result<OutboxEntry, SyncFailure>> retry(OutboxEntryId id) async {
    final resolved = await _resolve(id);
    if (resolved.isSuccess) await _announce();
    return resolved;
  }

  /// Emits the queue's state whenever it changes, starting with the state at
  /// the moment of subscription.
  ///
  /// A fresh stream per call rather than one shared broadcast stream, so that
  /// a badge appearing halfway through a shift does not sit blank until the
  /// next transition. If the initial read fails, the subscription starts with
  /// no value rather than an error: this is a notification channel, and a
  /// screen that cannot show a count is not a screen that should crash.
  @override
  Stream<SyncStatus> statusChanges() async* {
    final current = await _readStatus(());
    if (current case Success(value: final status)) yield status;
    yield* _statuses.stream;
  }

  /// Releases the status stream.
  ///
  /// Called by the composition root when the container is torn down. The
  /// coordinator owns the controller, so it is the only thing that can.
  Future<void> dispose() => _statuses.close();

  Future<void> _announce() async {
    final status = await _readStatus(());
    if (status case Success(:final value)) _statuses.add(value);
  }
}
