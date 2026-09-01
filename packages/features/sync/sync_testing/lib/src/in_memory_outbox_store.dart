import 'package:core_kernel/core_kernel.dart';
import 'package:sync_api/sync_api.dart';

/// An `OutboxStore` that really keeps entries, in a map.
///
/// A fake, not a mock: it stores what it is given, orders what it hands back,
/// and remembers a cursor — so a test written against it exercises the drain's
/// logic rather than a script of expected calls.
///
/// It passes `runOutboxStoreContract`, and so does the drift-backed adapter in
/// `sync_infrastructure`. It is also a *product* adapter, not only a test one:
/// scenario 5's table binds it in `app_dispatcher`, where the operator is at a
/// desk with a connection and durability across a crash buys nothing. That is
/// why it lives in `sync_testing` rather than being written twice — the
/// contract kit is what keeps the two uses honest.
final class InMemoryOutboxStore implements OutboxStore {
  final Map<String, OutboxEntry> _entries = {};
  final List<SyncFailure> _queuedFailures = [];

  SyncCursor _cursor = SyncCursor.beginning;

  /// Makes the next call — whichever it is — return [failure].
  ///
  /// Failure is part of a port's contract, so the fake standing in for that
  /// contract has to be able to produce it. Without this, the branch a drain
  /// takes when the database is locked stays untested, and that is the branch
  /// that runs on a bad day.
  void failNextWith(SyncFailure failure) => _queuedFailures.add(failure);

  /// Everything the store currently holds, in insertion order.
  List<OutboxEntry> get stored => List.unmodifiable(_entries.values);

  @override
  Future<Result<void, SyncFailure>> put(OutboxEntry entry) async {
    final failure = _takeFailure();
    if (failure != null) return Failed(failure);

    _entries[entry.id.value] = entry;
    return const Success(null);
  }

  @override
  Future<Result<OutboxEntry, SyncFailure>> byId(OutboxEntryId id) async {
    final failure = _takeFailure();
    if (failure != null) return Failed(failure);

    final entry = _entries[id.value];
    if (entry == null) {
      return Failed(
        MalformedEntry(field: 'id', reason: 'no entry ${id.value}'),
      );
    }
    return Success(entry);
  }

  @override
  Future<Result<List<OutboxEntry>, SyncFailure>> pending({
    int limit = 50,
  }) async {
    final failure = _takeFailure();
    if (failure != null) return Failed(failure);

    return Success(
      _ordered.where((entry) => !entry.isBlocked).take(limit).toList(),
    );
  }

  @override
  Future<Result<List<OutboxEntry>, SyncFailure>> blocked() async {
    final failure = _takeFailure();
    if (failure != null) return Failed(failure);

    return Success(_ordered.where((entry) => entry.isBlocked).toList());
  }

  @override
  Future<Result<void, SyncFailure>> drop(OutboxEntryId id) async {
    final failure = _takeFailure();
    if (failure != null) return Failed(failure);

    _entries.remove(id.value);
    return const Success(null);
  }

  @override
  Future<Result<SyncCursor, SyncFailure>> cursor() async {
    final failure = _takeFailure();
    if (failure != null) return Failed(failure);

    return Success(_cursor);
  }

  @override
  Future<Result<void, SyncFailure>> saveCursor(SyncCursor cursor) async {
    final failure = _takeFailure();
    if (failure != null) return Failed(failure);

    _cursor = cursor;
    return const Success(null);
  }

  @override
  Future<Result<void, SyncFailure>> recordAttempt(
    OutboxEntryId id, {
    required DateTime at,
    required DateTime nextAttemptAt,
  }) async {
    final failure = _takeFailure();
    if (failure != null) return Failed(failure);

    // Read from the map rather than from anything a caller handed over: the
    // count this increments is the store's, which is what the drift adapter's
    // `attempt_count = attempt_count + 1` says in SQL.
    final stored = _entries[id.value];
    if (stored == null) return const Success(null);

    _entries[id.value] = stored.attempted(
      at: at,
      backoff: nextAttemptAt.difference(at),
    );
    return const Success(null);
  }

  @override
  Future<Result<void, SyncFailure>> accepted(
    OutboxEntryId id,
    SyncCursor cursor,
  ) async {
    final failure = _takeFailure();
    if (failure != null) return Failed(failure);

    // Atomic by construction: there is no await between the two mutations, so
    // nothing can observe one without the other. The drift adapter needs a
    // transaction to make the same promise, and its own test proves it.
    _entries.remove(id.value);
    _cursor = cursor;
    return const Success(null);
  }

  /// Oldest first, and stable when two entries were queued in the same
  /// millisecond.
  ///
  /// The tie-break on the identifier is not decoration. A `Map` preserves
  /// insertion order, so without it a store that had been read back from disk
  /// — where insertion order is gone — would order differently from one that
  /// had not, and the contract kit would pass against the fake and fail
  /// against the adapter.
  List<OutboxEntry> get _ordered {
    final entries = _entries.values.toList()
      ..sort((a, b) {
        final byTime = a.queuedAt.compareTo(b.queuedAt);
        return byTime != 0 ? byTime : a.id.value.compareTo(b.id.value);
      });
    return entries;
  }

  SyncFailure? _takeFailure() =>
      _queuedFailures.isEmpty ? null : _queuedFailures.removeAt(0);
}
