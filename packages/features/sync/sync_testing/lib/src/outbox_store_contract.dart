import 'package:core_kernel/core_kernel.dart';
import 'package:sync_api/sync_api.dart';
import 'package:test/test.dart';

import 'outbox_entry_builder.dart';

/// The behaviour every `OutboxStore` has to have, whatever is behind it.
///
/// Call it from a test in any package that ships an implementation:
///
/// ```dart
/// void main() {
///   runOutboxStoreContract(InMemoryOutboxStore.new);
/// }
/// ```
///
/// The same suite runs against the in-memory store here and against
/// `DriftOutboxStore` in `sync_infrastructure`. That is what stops the two
/// drifting apart — and this port is the one where drift would hurt most,
/// because `app_dispatcher` ships the in-memory store as a *product* adapter
/// rather than only as a test double.
///
/// [createStore] must return a *fresh, empty* store on every call. The suite
/// calls it once per test, and a store shared between tests makes the order
/// they run in part of the result.
void runOutboxStoreContract(OutboxStore Function() createStore) {
  group('OutboxStore contract', () {
    late OutboxStore store;

    final earlier = DateTime.utc(2026, 3, 14, 8);
    final noon = DateTime.utc(2026, 3, 14, 12);
    final later = DateTime.utc(2026, 3, 14, 16);

    setUp(() => store = createStore());

    Future<OutboxEntry> put(OutboxEntry entry) async {
      final written = await store.put(entry);
      expect(written.isSuccess, isTrue, reason: 'setup failed: $written');
      return entry;
    }

    group('put and byId', () {
      test('reads back what was written', () async {
        final entry = await put(OutboxEntryBuilder().withId('e-1').build());

        expect(
          await store.byId(entry.id),
          Success<OutboxEntry, SyncFailure>(entry),
        );
      });

      test('preserves the routing key, the body and the policy', () async {
        // The three things sync is not allowed to interpret. An
        // implementation that normalised any of them would corrupt a
        // feature's payload without ever being able to tell.
        final entry = await put(
          OutboxEntryBuilder()
              .withId('e-1')
              .ofType('delivery.completeAttempt')
              .under(const ConflictPolicy.manualReview())
              .build(),
        );

        final read = await store.byId(entry.id);
        final stored = read.fold((e) => e, (f) => throw StateError('$f'));

        expect(stored.type, 'delivery.completeAttempt');
        expect(stored.payload, entry.payload);
        expect(stored.policy, const ConflictPolicy.manualReview());
      });

      test('preserves the attempt count and the schedule', () async {
        // The reason nextAttemptAt is stored rather than recomputed: it has to
        // survive a restart, or a device that was killed mid-backoff comes
        // back and retries everything at once.
        final entry = await put(
          OutboxEntryBuilder()
              .withId('e-1')
              .attempted(at: noon, backoff: const Duration(minutes: 4))
              .build(),
        );

        final read = await store.byId(entry.id);
        final stored = read.fold((e) => e, (f) => throw StateError('$f'));

        expect(stored.attempts, 1);
        expect(stored.lastAttemptAt, noon);
        expect(stored.nextAttemptAt, noon.add(const Duration(minutes: 4)));
      });

      test(
        'is an upsert: writing the same id twice leaves one entry',
        () async {
          // The property that makes queueing idempotent. A feature that crashed
          // between generating an identifier and writing the row retries with
          // the same identifier, and two rows here is two payments at the door.
          await put(OutboxEntryBuilder().withId('e-1').build());
          await put(
            OutboxEntryBuilder()
                .withId('e-1')
                .attempted(at: noon, backoff: const Duration(seconds: 2))
                .build(),
          );

          final pending = await store.pending();
          final rows = pending.fold((r) => r, (f) => throw StateError('$f'));

          expect(rows, hasLength(1));
          expect(rows.single.attempts, 1);
        },
      );

      test('reports an identifier it does not hold', () async {
        final missing = OutboxEntryId.parse(
          'nope',
        ).fold((id) => id, (f) => throw StateError('$f'));

        expect((await store.byId(missing)).isFailure, isTrue);
      });
    });

    group('pending', () {
      test('is empty rather than a failure on a fresh device', () async {
        // Nothing queued is an ordinary state, not an error. An implementation
        // that failed here would put a warning on a courier's screen before
        // their first scan of the day.
        final pending = await store.pending();

        expect(pending.fold((r) => r, (f) => throw StateError('$f')), isEmpty);
      });

      test('returns entries oldest first', () async {
        // Ordering is contract, not detail. Work queued earlier describes a
        // world the later work assumes: a payment drained before the delivery
        // it belongs to reaches a server that has not been told about the
        // shipment.
        await put(
          OutboxEntryBuilder().withId('c').queuedAt(later).build(),
        );
        await put(
          OutboxEntryBuilder().withId('a').queuedAt(earlier).build(),
        );
        await put(OutboxEntryBuilder().withId('b').queuedAt(noon).build());

        final pending = await store.pending();
        final rows = pending.fold((r) => r, (f) => throw StateError('$f'));

        expect(rows.map((row) => row.id.value), ['a', 'b', 'c']);
      });

      test('leaves blocked entries out', () async {
        // The other half of "a blocked entry is skipped, not deleted": it is
        // still in the store, and the drain never sees it.
        await put(OutboxEntryBuilder().withId('a').build());
        await put(
          OutboxEntryBuilder().withId('b').blocked('rejected').build(),
        );

        final pending = await store.pending();
        final rows = pending.fold((r) => r, (f) => throw StateError('$f'));

        expect(rows.map((row) => row.id.value), ['a']);
      });

      test('honours the limit', () async {
        for (final id in ['a', 'b', 'c']) {
          await put(OutboxEntryBuilder().withId(id).build());
        }

        final pending = await store.pending(limit: 2);
        final rows = pending.fold((r) => r, (f) => throw StateError('$f'));

        expect(rows, hasLength(2));
      });
    });

    group('blocked', () {
      test('returns exactly what pending leaves out', () async {
        await put(OutboxEntryBuilder().withId('a').build());
        await put(
          OutboxEntryBuilder()
              .withId('b')
              .blocked('server rejected: unknown shipment')
              .build(),
        );

        final blocked = await store.blocked();
        final rows = blocked.fold((r) => r, (f) => throw StateError('$f'));

        expect(rows.map((row) => row.id.value), ['b']);
        expect(
          rows.single.blockedReason,
          'server rejected: unknown shipment',
        );
      });

      test('is empty when nothing needs a person', () async {
        await put(OutboxEntryBuilder().withId('a').build());

        final blocked = await store.blocked();

        expect(blocked.fold((r) => r, (f) => throw StateError('$f')), isEmpty);
      });
    });

    group('drop', () {
      test('removes the entry', () async {
        final entry = await put(OutboxEntryBuilder().withId('e-1').build());

        expect((await store.drop(entry.id)).isSuccess, isTrue);

        final pending = await store.pending();
        expect(pending.fold((r) => r, (f) => throw StateError('$f')), isEmpty);
      });

      test('dropping what is not there succeeds', () async {
        // A drain that crashed after the server accepted and before the row
        // was removed retries the removal. The second attempt is not an error,
        // and an implementation that made it one would block the queue on a
        // piece of work that has already landed.
        final missing = OutboxEntryId.parse(
          'nope',
        ).fold((id) => id, (f) => throw StateError('$f'));

        expect((await store.drop(missing)).isSuccess, isTrue);
      });
    });

    group('recordAttempt', () {
      test('counts the attempt and schedules the next one', () async {
        final entry = await put(OutboxEntryBuilder().withId('e-1').build());

        final recorded = await store.recordAttempt(
          entry.id,
          at: noon,
          nextAttemptAt: later,
        );

        expect(recorded.isSuccess, isTrue);
        final stored = (await store.byId(entry.id)).fold(
          (value) => value,
          (failure) => throw StateError('$failure'),
        );
        expect(stored.attempts, entry.attempts + 1);
        expect(stored.lastAttemptAt, noon);
        expect(stored.isDueAt(later), isTrue);
        expect(stored.isDueAt(noon), isFalse);
      });

      test(
        'counts from what is stored, not from what a caller holds',
        () async {
          final entry = await put(OutboxEntryBuilder().withId('e-1').build());

          // Two records against the same in-hand entry. An implementation that
          // read, added one and wrote back would answer 1 twice; the count is
          // the store's, and it is what the retry schedule is spent against.
          await store.recordAttempt(entry.id, at: noon, nextAttemptAt: later);
          await store.recordAttempt(entry.id, at: noon, nextAttemptAt: later);

          final stored = (await store.byId(entry.id)).fold(
            (value) => value,
            (failure) => throw StateError('$failure'),
          );
          expect(stored.attempts, entry.attempts + 2);
        },
      );

      test('changes nothing else about the entry', () async {
        final entry = await put(
          OutboxEntryBuilder()
              .withId('e-1')
              .ofType('delivery.completeAttempt')
              .under(const ConflictPolicy.manualReview())
              .build(),
        );

        await store.recordAttempt(entry.id, at: noon, nextAttemptAt: later);

        final stored = (await store.byId(entry.id)).fold(
          (value) => value,
          (failure) => throw StateError('$failure'),
        );
        // The three things sync is not allowed to interpret survive a failed
        // attempt. An implementation that rewrote the whole row from a copy
        // the caller was holding could lose any of them.
        expect(stored.type, entry.type);
        expect(stored.payload, entry.payload);
        expect(stored.policy, entry.policy);
        expect(stored.queuedAt, entry.queuedAt);
      });

      test('it answers the count it wrote', () async {
        // The property the drain spends its retry budget against. An
        // implementation that answered the caller's number rather than its own
        // would let two drains each believe they were within budget while the
        // store had gone past it.
        final entry = await put(OutboxEntryBuilder().withId('e-1').build());

        final first = await store.recordAttempt(
          entry.id,
          at: noon,
          nextAttemptAt: later,
        );
        final second = await store.recordAttempt(
          entry.id,
          at: noon,
          nextAttemptAt: later,
        );

        expect(first.fold((count) => count, (f) => -1), entry.attempts + 1);
        expect(second.fold((count) => count, (f) => -1), entry.attempts + 2);
      });

      test('recording against an entry that is not there succeeds', () async {
        final missing = OutboxEntryId.parse(
          'nope',
        ).fold((id) => id, (f) => throw StateError('$f'));

        // Same reasoning as drop: a drain racing a person who resolved the
        // entry must not stop on work that is no longer queued. Zero rather
        // than one, because a caller reading it as an attempt count would give
        // up on work that has already gone.
        expect(
          (await store.recordAttempt(
            missing,
            at: noon,
            nextAttemptAt: later,
          )).fold((count) => count, (f) => -1),
          0,
        );
      });
    });

    group('block', () {
      test('takes the entry out of the drain and leaves it findable', () async {
        final entry = await put(OutboxEntryBuilder().withId('e-1').build());

        final blocked = await store.block(entry.id, 'rejected: 422');

        expect(blocked.isSuccess, isTrue);
        expect(
          (await store.pending()).fold((r) => r, (f) => throw StateError('$f')),
          isEmpty,
        );
        final left = (await store.blocked()).fold(
          (rows) => rows,
          (f) => throw StateError('$f'),
        );
        expect(left.single.id, entry.id);
        expect(left.single.blockedReason, 'rejected: 422');
      });

      test('the first reason stands', () async {
        // What a person opening the review queue needs to read is the thing
        // that went wrong, not the symptom a later drain recorded. A second
        // drain overwriting "rejected: 422" with "gave up after 5 attempts"
        // hides the cause behind the count.
        final entry = await put(OutboxEntryBuilder().withId('e-1').build());

        await store.block(entry.id, 'rejected: 422');
        await store.block(entry.id, 'gave up after 5 attempts');

        final left = (await store.blocked()).fold(
          (rows) => rows,
          (f) => throw StateError('$f'),
        );
        expect(left.single.blockedReason, 'rejected: 422');
      });

      test('changes nothing else about the entry', () async {
        final entry = await put(
          OutboxEntryBuilder()
              .withId('e-1')
              .ofType('delivery.completeAttempt')
              .under(const ConflictPolicy.manualReview())
              .build(),
        );
        await store.recordAttempt(entry.id, at: noon, nextAttemptAt: later);

        await store.block(entry.id, 'rejected: 422');

        final left = (await store.blocked()).fold(
          (rows) => rows.single,
          (f) => throw StateError('$f'),
        );
        // The attempt counted a moment ago survives. Blocking used to write a
        // whole entry from a copy read before it, which rolled the count back.
        expect(left.attempts, entry.attempts + 1);
        expect(left.type, entry.type);
        expect(left.payload, entry.payload);
        expect(left.policy, entry.policy);
      });

      test('blocking an entry that is not there succeeds', () async {
        final missing = OutboxEntryId.parse(
          'nope',
        ).fold((id) => id, (f) => throw StateError('$f'));

        expect((await store.block(missing, 'whatever')).isSuccess, isTrue);
      });
    });

    group('accepted', () {
      test('removes the entry and moves the cursor', () async {
        final entry = await put(OutboxEntryBuilder().withId('e-1').build());

        final done = await store.accepted(entry.id, const SyncCursor('c-9'));

        expect(done.isSuccess, isTrue);
        final pending = await store.pending();
        expect(
          pending.fold((r) => r, (f) => throw StateError('$f')),
          isEmpty,
        );
        expect(
          await store.cursor(),
          const Success<SyncCursor, SyncFailure>(SyncCursor('c-9')),
        );
      });

      test('leaves the other entries queued', () async {
        final first = await put(
          OutboxEntryBuilder().withId('e-1').queuedAt(earlier).build(),
        );
        await put(OutboxEntryBuilder().withId('e-2').queuedAt(noon).build());

        await store.accepted(first.id, const SyncCursor('c-9'));

        final pending = (await store.pending()).fold(
          (r) => r,
          (f) => throw StateError('$f'),
        );
        expect(pending.map((entry) => entry.id.value), ['e-2']);
      });

      test('accepting what is not there still moves the cursor', () async {
        final missing = OutboxEntryId.parse(
          'nope',
        ).fold((id) => id, (f) => throw StateError('$f'));

        // A drain that crashed after this call and retried it finds no row
        // and has still been told where the server is. Refusing here would
        // stop the queue on work that has already landed.
        expect(
          (await store.accepted(missing, const SyncCursor('c-9'))).isSuccess,
          isTrue,
        );
        expect(
          await store.cursor(),
          const Success<SyncCursor, SyncFailure>(SyncCursor('c-9')),
        );
      });

      // **Atomicity is asserted per implementation, not here.** The kit has no
      // way to make an arbitrary store fail *between* its two writes, and a
      // contract test that could not produce the failure would be a paragraph
      // pretending to be an assertion. `sync_infrastructure` proves the
      // rollback against a real database; `InMemoryOutboxStore` is atomic by
      // construction, because it does not await between the two mutations.
    });

    group('cursor', () {
      test(
        'a device that has never synchronised is at the beginning',
        () async {
          final cursor = await store.cursor();

          expect(
            cursor,
            const Success<SyncCursor, SyncFailure>(SyncCursor.beginning),
            reason: 'having no position is a state, not a failure',
          );
        },
      );

      test('reads back what was saved', () async {
        expect(
          (await store.saveCursor(const SyncCursor('c-9'))).isSuccess,
          isTrue,
        );

        expect(
          await store.cursor(),
          const Success<SyncCursor, SyncFailure>(SyncCursor('c-9')),
        );
      });

      test('the last write wins', () async {
        await store.saveCursor(const SyncCursor('c-1'));
        await store.saveCursor(const SyncCursor('c-2'));

        expect(
          await store.cursor(),
          const Success<SyncCursor, SyncFailure>(SyncCursor('c-2')),
        );
      });
    });

    group('the port never throws', () {
      test('every method reports failure as a Failed instead', () async {
        // Invariant 1.2.9. An implementation that threw would satisfy every
        // assertion above and still break the first caller that relied on the
        // return type telling the whole story.
        final missing = OutboxEntryId.parse(
          'nope',
        ).fold((id) => id, (f) => throw StateError('$f'));

        expect((await store.byId(missing)).isFailure, isTrue);
        expect((await store.drop(missing)).isSuccess, isTrue);
        expect((await store.pending()).isSuccess, isTrue);
        expect((await store.blocked()).isSuccess, isTrue);
        expect((await store.cursor()).isSuccess, isTrue);
      });
    });
  });
}
