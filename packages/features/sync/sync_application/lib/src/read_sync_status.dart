import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:sync_api/sync_api.dart';

/// Works out what the queue is currently doing.
///
/// Its own use case rather than a private method on the drain, because three
/// callers need the same answer and would otherwise each compute a slightly
/// different one: the drain reports it when it finishes, the coordinator emits
/// it after a queue changes, and a screen reads it when it opens.
///
/// The order of the checks is the interesting part, and it is a product
/// decision rather than an obvious one. Blocked work is reported even when
/// there is no connection, because "two of these need you" outranks "you are
/// in a basement" — the second resolves itself and the first does not.
final class ReadSyncStatus
    implements UseCase<(), Result<SyncStatus, SyncFailure>> {
  /// Creates the use case.
  const ReadSyncStatus({
    required this._store,
    required this._network,
    required this._clock,
    this.batchSize = 50,
  });

  final OutboxStore _store;
  final NetworkStatus _network;
  final Clock _clock;

  /// How many entries a single look at the queue considers.
  ///
  /// The same bound the drain uses, so that the count a screen shows and the
  /// count the drain works through cannot disagree.
  final int batchSize;

  @override
  Future<Result<SyncStatus, SyncFailure>> call(() input) async {
    final pending = await _store.pending(limit: batchSize);
    if (pending case Failed(:final failure)) return Failed(failure);

    final blocked = await _store.blocked();
    if (blocked case Failed(:final failure)) return Failed(failure);

    final queued = pending.fold((rows) => rows, (_) => const <OutboxEntry>[]);
    final needingReview = blocked.fold(
      (rows) => rows,
      (_) => const <OutboxEntry>[],
    );

    if (needingReview.isNotEmpty) {
      return Success(
        SyncStatus.blocked(
          pending: queued.length,
          needingReview: needingReview.length,
        ),
      );
    }

    if (queued.isEmpty) return const Success(SyncIdle());

    final count = queued.length;
    if (_network.current == NetworkCondition.offline) {
      return Success(SyncStatus.waitingForNetwork(pending: count));
    }

    // Anything due means the drain has more to do than its last batch
    // carried. Reporting it as `draining` is this feature's way of saying
    // "call me again" rather than "a retry is scheduled".
    final now = _clock.now();
    final due = queued.where((entry) => entry.isDueAt(now));
    if (due.isNotEmpty) return Success(SyncStatus.draining(pending: count));

    // Nothing is due, so every entry has a scheduled instant; the earliest one
    // is when the queue next has something to do.
    final next = queued
        .map((entry) => entry.nextAttemptAt)
        .nonNulls
        .reduce((a, b) => a.isBefore(b) ? a : b);
    return Success(
      SyncStatus.waitingToRetry(pending: count, nextAttemptAt: next),
    );
  }
}
