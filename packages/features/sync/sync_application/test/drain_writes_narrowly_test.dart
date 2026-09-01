@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:core_testing/core_testing.dart';
import 'package:sync_api/sync_api.dart';
import 'package:sync_application/sync_application.dart';
import 'package:sync_testing/sync_testing.dart';
import 'package:test/test.dart';

/// What the drain is allowed to write, and what it is not allowed to clobber.
///
/// The drain reads a batch at the top of a pass and then spends one network
/// round trip per entry inside it. Every value it holds is therefore a
/// snapshot, and writing it back whole — which is what `OutboxStore.put` does
/// — puts everything that changed in the meantime back to what it was.
///
/// Both tests below fail against a drain that writes through `put`, and each
/// names the thing that goes wrong rather than the call that was made.
void main() {
  final noon = DateTime.utc(2026, 3, 14, 12);

  OutboxEntry entry(String id) => OutboxEntryBuilder()
      .withId(id)
      .queuedAt(noon)
      .ofType('test.write')
      .build();

  DrainOutbox drainOver(OutboxStore store, CommandTransportPort transport) =>
      DrainOutbox(
        store: store,
        transport: transport,
        skew: FakeClockSkew(),
        clock: FakeClock(noon),
        random: FakeRandomSource(),
        network: FakeNetworkStatus(),
        logger: RecordingLogger(),
        status: ReadSyncStatus(
          store: store,
          network: FakeNetworkStatus(),
          clock: FakeClock(noon),
        ),
      );

  test(
    'a failed attempt does not resurrect an entry somebody blocked',
    () async {
      final store = InMemoryOutboxStore();
      final queued = entry('e-1');
      await store.put(queued);

      // The mutation happens during the send, which is exactly where the real
      // one happens: the drain is holding a snapshot and waiting on a network
      // round trip while somebody, or another code path, changes the row.
      final transport = _MutatingTransport(
        FakeCommandTransport(),
        onSend: () => store.put(queued.blocked('a person stopped this')),
        failWith: const SyncTransportFailed(detail: 'reset'),
      );

      await drainOver(store, transport)(());

      final blocked = (await store.blocked()).fold(
        (rows) => rows,
        (failure) => throw StateError('$failure'),
      );
      // A drain that wrote the whole row back would have put the entry into the
      // queue again with no reason on it, and the next pass would send work a
      // person had deliberately stopped.
      expect(blocked.map((row) => row.id.value), ['e-1']);
      expect(blocked.single.blockedReason, 'a person stopped this');
    },
  );

  test(
    'a store that cannot save a cursor on its own does not lose the work',
    () async {
      final store = _NoCursorWrites(InMemoryOutboxStore());
      await store.put(entry('e-1'));

      final status = await drainOver(store, FakeCommandTransport())(());

      // The accept path makes one call, so there is no window in which the row
      // is gone and the cursor is not saved. A drain that dropped the row and
      // then saved the cursor separately would have reported this failure with
      // the work already deleted — accepted by the server, forgotten by the
      // device, and impossible to tell apart from work that was never queued.
      expect(status.isSuccess, isTrue);
      final pending = (await store.pending()).fold(
        (rows) => rows,
        (failure) => throw StateError('$failure'),
      );
      expect(pending, isEmpty);
      expect(
        await store.cursor(),
        isA<Success<SyncCursor, SyncFailure>>().having(
          (result) => result.value.isBeginning,
          'moved off the beginning',
          isFalse,
        ),
      );
    },
  );
}

/// Runs [onSend] before every send, and optionally fails afterwards.
///
/// The seam a test needs to change the store while the drain is mid-entry.
/// Nothing else in the fakes offers one, because nothing else needed it.
final class _MutatingTransport implements CommandTransportPort {
  _MutatingTransport(this._inner, {required this.onSend, this.failWith});

  final CommandTransportPort _inner;

  /// What happens while the drain is waiting on this send.
  final Future<void> Function() onSend;

  /// What the send answers, or null to let the inner transport answer.
  final SyncFailure? failWith;

  @override
  Future<Result<SyncCursor, SyncFailure>> send(SyncEnvelope envelope) async {
    await onSend();
    final failure = failWith;
    return failure == null ? _inner.send(envelope) : Failed(failure);
  }
}

/// A store whose standalone cursor write always fails.
///
/// `accepted` still works, because saving the cursor as part of accepting is a
/// different statement from saving it on its own — which is the whole point of
/// the two being one method.
final class _NoCursorWrites implements OutboxStore {
  _NoCursorWrites(this._inner);

  final OutboxStore _inner;

  @override
  Future<Result<void, SyncFailure>> saveCursor(SyncCursor cursor) async =>
      const Failed(OutboxUnavailable(detail: 'cursor writes are refused'));

  @override
  Future<Result<void, SyncFailure>> accepted(
    OutboxEntryId id,
    SyncCursor cursor,
  ) => _inner.accepted(id, cursor);

  @override
  Future<Result<void, SyncFailure>> put(OutboxEntry entry) => _inner.put(entry);

  @override
  Future<Result<OutboxEntry, SyncFailure>> byId(OutboxEntryId id) =>
      _inner.byId(id);

  @override
  Future<Result<List<OutboxEntry>, SyncFailure>> pending({int limit = 50}) =>
      _inner.pending(limit: limit);

  @override
  Future<Result<List<OutboxEntry>, SyncFailure>> blocked() => _inner.blocked();

  @override
  Future<Result<void, SyncFailure>> drop(OutboxEntryId id) => _inner.drop(id);

  @override
  Future<Result<SyncCursor, SyncFailure>> cursor() => _inner.cursor();

  @override
  Future<Result<void, SyncFailure>> recordAttempt(
    OutboxEntryId id, {
    required DateTime at,
    required DateTime nextAttemptAt,
  }) => _inner.recordAttempt(id, at: at, nextAttemptAt: nextAttemptAt);
}
