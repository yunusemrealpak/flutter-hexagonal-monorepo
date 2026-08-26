import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:sync_api/sync_api.dart';

/// Reads the work the queue gave up on.
///
/// A use case rather than a pass-through on the coordinator, because the
/// review queue is a product surface: somebody at a depot opens it, reads why
/// each entry stopped, and decides. What it must never become is a place where
/// the payloads are decoded and rendered — this package cannot decode them,
/// which is the constraint that keeps that from happening by accident.
final class LoadReviewQueue
    implements UseCase<(), Result<List<OutboxEntry>, SyncFailure>> {
  /// Creates the use case.
  const LoadReviewQueue({required this._store});

  final OutboxStore _store;

  @override
  Future<Result<List<OutboxEntry>, SyncFailure>> call(() input) =>
      _store.blocked();
}

/// Puts one blocked entry back into the queue.
///
/// The attempt count is deliberately preserved. An entry that has been round
/// this loop twice is visibly not a fresh one, and resetting the count would
/// hand it another full budget of retries every time somebody pressed the
/// button — which is how a permanently broken command becomes a permanent
/// load on the server.
///
/// The backoff *is* cleared, so the entry is due on the next drain: a person
/// who just resolved something is entitled to see it move.
final class ResolveBlockedEntry
    implements UseCase<OutboxEntryId, Result<OutboxEntry, SyncFailure>> {
  /// Creates the use case.
  const ResolveBlockedEntry({required this._store, required this._logger});

  final OutboxStore _store;
  final Logger _logger;

  @override
  Future<Result<OutboxEntry, SyncFailure>> call(OutboxEntryId id) async {
    final OutboxEntry blocked;
    switch (await _store.byId(id)) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        blocked = value;
    }

    // Unblocking something that is not blocked succeeds and changes nothing.
    // Two people looking at the same review queue is the ordinary case, and
    // reporting the second press as an error would say the queue is broken
    // when it is merely already fixed.
    if (!blocked.isBlocked) return Success(blocked);

    final entry = blocked.unblocked();
    final written = await _store.put(entry);
    if (written case Failed(:final failure)) return Failed(failure);

    _logger.info(
      'blocked work put back in the queue',
      context: {'entry': entry.id.value, 'attempts': entry.attempts},
    );
    return Success(entry);
  }
}
