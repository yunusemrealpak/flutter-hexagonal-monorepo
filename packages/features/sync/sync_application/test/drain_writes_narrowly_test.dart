@Tags(['unit'])
library;

import 'dart:async';

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

  DrainOutbox drainOver(
    OutboxStore store,
    CommandTransportPort transport, {
    RetrySchedule schedule = RetrySchedule.standard,
  }) => DrainOutbox(
    schedule: schedule,
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
    'two drains cannot spend the retry budget twice',
    () async {
      // The race a background scheduler makes real: the app's own orchestrator
      // and a task the operating system started are two drains over one store.
      // Both read the entry, both send, and both then decide whether to give
      // up. Deciding from the count each of them *read* lets both conclude
      // they are within budget while the store has gone past it.
      final schedule = RetrySchedule.of(
        baseDelay: const Duration(seconds: 1),
        maxDelay: const Duration(minutes: 1),
        maxAttempts: 3,
      ).fold((value) => value, (failure) => throw StateError('bad schedule'));

      final store = InMemoryOutboxStore();
      await store.put(
        OutboxEntryBuilder()
            .withId('e-1')
            .queuedAt(noon)
            .ofType('test.write')
            // One attempt already spent, so a single further one is inside the
            // budget and a second is not. That is the only arrangement in
            // which the two answers differ — and the attempt is put an hour
            // back so the entry is due now rather than waiting out its own
            // backoff.
            .attempted(at: noon.subtract(const Duration(hours: 1)))
            .build(),
      );

      // Both drains are held inside `send` until both have got there, which is
      // the interleaving and the only place it can happen: a drain is holding
      // its snapshot exactly while it waits on the network.
      final gate = Completer<void>();
      var arrived = 0;
      final transport = _GatedTransport(
        onSend: () async {
          arrived++;
          if (arrived == 2) gate.complete();
          await gate.future;
        },
      );

      await Future.wait([
        drainOver(store, transport, schedule: schedule)(()),
        drainOver(store, transport, schedule: schedule)(()),
      ]);

      final blocked = (await store.blocked()).fold(
        (rows) => rows,
        (failure) => throw StateError(r'$failure'),
      );
      // Three attempts against a budget of three, and the entry is out of the
      // drain. Deciding from the snapshot leaves it queued with three attempts
      // on it and a fourth still to come.
      expect(blocked.map((row) => row.id.value), ['e-1']);
      expect(blocked.single.attempts, 3);
      expect(
        (await store.pending()).fold((r) => r, (f) => throw StateError(r'$f')),
        isEmpty,
      );
    },
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

/// A transport that holds every send until it is let go.
///
/// It always fails, transiently, because what this is for is the decision a
/// drain makes *after* a failed attempt.
final class _GatedTransport implements CommandTransportPort {
  _GatedTransport({required this.onSend});

  final Future<void> Function() onSend;

  @override
  Future<Result<SyncCursor, SyncFailure>> send(SyncEnvelope envelope) async {
    await onSend();
    return const Failed(SyncTransportFailed(detail: 'reset'));
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
  Future<Result<int, SyncFailure>> recordAttempt(
    OutboxEntryId id, {
    required DateTime at,
    required DateTime nextAttemptAt,
  }) => _inner.recordAttempt(id, at: at, nextAttemptAt: nextAttemptAt);

  @override
  Future<Result<void, SyncFailure>> block(OutboxEntryId id, String reason) =>
      _inner.block(id, reason);
}
