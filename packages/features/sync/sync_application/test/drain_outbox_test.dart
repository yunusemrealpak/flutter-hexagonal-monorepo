@Tags(['unit'])
library;

import 'package:core_ports/core_ports.dart';
import 'package:sync_api/sync_api.dart';
import 'package:sync_testing/sync_testing.dart';
import 'package:test/test.dart';

import 'support/harness.dart';

void main() {
  late Harness harness;

  OutboxEntry entry(String id, {String type = 'test.write'}) =>
      OutboxEntryBuilder()
          .withId(id)
          .ofType(type)
          .queuedAt(Harness.noon)
          .build();

  setUp(() => harness = Harness());

  group('the happy path', () {
    test('sends every due entry and removes what landed', () async {
      await harness.seed(entry('e-1'));
      await harness.seed(entry('e-2'));

      final status = unwrap(await harness.drain(()));

      expect(harness.transport.accepted, 2);
      expect(await harness.pending(), isEmpty);
      expect(status, const SyncStatus.idle());
    });

    test('sends oldest first', () async {
      // Ordering matters across features: a payment drained before the
      // delivery it belongs to reaches a server that has not been told about
      // the shipment.
      await harness.seed(
        OutboxEntryBuilder()
            .withId('late')
            .queuedAt(Harness.noon.add(const Duration(hours: 1)))
            .build(),
      );
      await harness.seed(
        OutboxEntryBuilder()
            .withId('early')
            .queuedAt(Harness.noon.subtract(const Duration(hours: 1)))
            .build(),
      );

      await harness.drain(());

      expect(
        harness.transport.received.map((e) => e.id.value),
        ['early', 'late'],
      );
    });

    test('advances the cursor as the server accepts work', () async {
      await harness.seed(entry('e-1'));

      await harness.drain(());

      final cursor = unwrap(await harness.store.cursor());
      expect(cursor.isBeginning, isFalse);
    });

    test(
      'the next envelope carries the position the last one earned',
      () async {
        await harness.seed(entry('e-1'));
        await harness.seed(entry('e-2'));

        await harness.drain(());

        expect(harness.transport.received.first.cursor, SyncCursor.beginning);
        expect(harness.transport.received.last.cursor.isBeginning, isFalse);
      },
    );

    test('corrects the queued instant by the skew it was told', () async {
      harness.skew.reports(const Duration(minutes: 2));
      await harness.seed(entry('e-1'));

      await harness.drain(());

      expect(
        harness.transport.received.single.queuedAt,
        Harness.noon.add(const Duration(minutes: 2)),
      );
    });

    test('drains without a skew when the port cannot answer', () async {
      // Not knowing the correction improves ordering between devices; not
      // sending the work at all improves nothing.
      harness.skew.failsWith(const SyncOffline());
      await harness.seed(entry('e-1'));

      await harness.drain(());

      expect(harness.transport.accepted, 1);
      expect(harness.transport.received.single.queuedAt, Harness.noon);
    });
  });

  group('offline', () {
    test(
      'does not send anything when the device knows it is offline',
      () async {
        harness = Harness(connection: NetworkCondition.offline);
        await harness.seed(entry('e-1'));

        final status = unwrap(await harness.drain(()));

        expect(harness.transport.received, isEmpty);
        expect(status, const SyncStatus.waitingForNetwork(pending: 1));
      },
    );

    test('stops mid-drain without counting the attempt', () async {
      // The decision this use case exists to demonstrate. Counting an offline
      // failure as an attempt would let a device in a tunnel burn its whole
      // budget in a single pass — eight failures in eight milliseconds — and
      // block a shift's work for manual review because of a lift.
      harness.transport.failEveryTypeOf('test.write', const SyncOffline());
      await harness.seed(entry('e-1'));
      await harness.seed(entry('e-2'));

      await harness.drain(());

      final queued = await harness.pending();
      expect(queued, hasLength(2));
      expect(queued.every((row) => row.attempts == 0), isTrue);
      expect(await harness.blocked(), isEmpty);
    });

    test('leaves the entries behind it untouched', () async {
      harness.transport.failEveryTypeOf('test.write', const SyncOffline());
      await harness.seed(entry('e-1'));
      await harness.seed(entry('e-2'));

      await harness.drain(());

      expect(harness.transport.received, hasLength(1));
    });
  });

  group('a transient failure', () {
    test('counts an attempt and schedules the next one', () async {
      harness.transport.failEveryTypeOf(
        'test.write',
        const SyncTransportFailed(detail: 'reset'),
      );
      await harness.seed(entry('e-1'));

      await harness.drain(());

      final row = (await harness.pending()).single;
      expect(row.attempts, 1);
      // The first backoff is one second, halved by the 0.5 jitter the fake
      // random source is scripted with.
      expect(
        row.nextAttemptAt,
        Harness.noon.add(const Duration(milliseconds: 500)),
      );
    });

    test('backs off exponentially across drains', () async {
      harness.transport.failEveryTypeOf(
        'test.write',
        const SyncTransportFailed(),
      );
      await harness.seed(entry('e-1'));

      final waits = <Duration>[];
      for (var i = 0; i < 3; i++) {
        await harness.drain(());
        final row = (await harness.pending()).single;
        waits.add(row.nextAttemptAt!.difference(harness.clock.now()));
        harness.clock.setTo(row.nextAttemptAt!);
      }

      expect(waits, [
        const Duration(milliseconds: 500),
        const Duration(seconds: 1),
        const Duration(seconds: 2),
      ]);
    });

    test('is not attempted again before its backoff has passed', () async {
      harness.transport.failEveryTypeOf(
        'test.write',
        const SyncTransportFailed(),
      );
      await harness.seed(entry('e-1'));

      await harness.drain(());
      await harness.drain(());

      expect(harness.transport.received, hasLength(1));
    });

    test('gives up after the schedule runs out', () async {
      harness = Harness(
        schedule: unwrap(
          RetrySchedule.of(
            baseDelay: const Duration(seconds: 1),
            maxDelay: const Duration(seconds: 4),
            maxAttempts: 2,
          ),
        ),
      );
      harness.transport.failEveryTypeOf(
        'test.write',
        const SyncTransportFailed(),
      );
      await harness.seed(entry('e-1'));

      await harness.drain(());
      harness.clock.advance(const Duration(minutes: 1));
      await harness.drain(());

      expect(await harness.pending(), isEmpty);
      expect(
        (await harness.blocked()).single.blockedReason,
        contains('gave up'),
      );
    });
  });

  group('a permanent failure', () {
    test('blocks the entry rather than retrying it', () async {
      harness.transport.failEveryTypeOf(
        'test.write',
        const SyncRejected(reason: 'unknown shipment', statusCode: 422),
      );
      await harness.seed(entry('e-1'));

      await harness.drain(());

      final blocked = (await harness.blocked()).single;
      expect(blocked.blockedReason, contains('unknown shipment'));
      expect(await harness.pending(), isEmpty);
    });

    test('does not stop the entries behind it', () async {
      // The failure mode a naive queue gets wrong: one bad entry at the head
      // and the shift's work never lands.
      harness.transport.failEveryTypeOf(
        'payments.collect',
        const SyncRejected(reason: 'unknown shipment'),
      );
      await harness.seed(entry('e-1', type: 'payments.collect'));
      await harness.seed(entry('e-2'));

      final status = unwrap(await harness.drain(()));

      expect(harness.transport.accepted, 1);
      expect(await harness.blocked(), hasLength(1));
      expect(status, const SyncStatus.blocked(pending: 0, needingReview: 1));
    });

    test('keeps the payload so a person can see what stopped', () async {
      harness.transport.failEveryTypeOf(
        'test.write',
        const SyncRejected(reason: 'unknown shipment'),
      );
      await harness.seed(entry('e-1'));

      await harness.drain(());

      expect((await harness.blocked()).single.payload, isNotEmpty);
      expect(harness.logger.recordsAt(LogLevel.warning), hasLength(1));
    });
  });

  group('a conflict', () {
    const conflict = SyncConflict(cursor: 'c-99', detail: 'newer write exists');

    test(
      'saves the position the server reported, whatever the policy',
      () async {
        harness.transport.failEveryTypeOf('test.write', conflict);
        await harness.seed(entry('e-1'));

        await harness.drain(());

        expect(unwrap(await harness.store.cursor()), const SyncCursor('c-99'));
      },
    );

    test('under lastWriteWins, tries again against the new position', () async {
      harness.transport.failEveryTypeOf('test.write', conflict);
      await harness.seed(
        OutboxEntryBuilder()
            .withId('e-1')
            .under(const ConflictPolicy.lastWriteWins())
            .queuedAt(Harness.noon)
            .build(),
      );

      await harness.drain(());
      harness.transport.recover('test.write');
      harness.clock.advance(const Duration(minutes: 1));
      await harness.drain(());

      expect(harness.transport.received.last.cursor, const SyncCursor('c-99'));
      expect(harness.transport.accepted, 1);
    });

    test('under serverWins, drops the entry without blocking it', () async {
      // The server's version stands, so this work is finished — not failed.
      // Blocking it would put a decision in front of a person who has nothing
      // left to decide.
      harness.transport.failEveryTypeOf('test.write', conflict);
      await harness.seed(
        OutboxEntryBuilder()
            .withId('e-1')
            .under(const ConflictPolicy.serverWins())
            .queuedAt(Harness.noon)
            .build(),
      );

      await harness.drain(());

      expect(await harness.pending(), isEmpty);
      expect(await harness.blocked(), isEmpty);
    });

    test('under manualReview, blocks it with the server detail', () async {
      harness.transport.failEveryTypeOf('test.write', conflict);
      await harness.seed(
        OutboxEntryBuilder()
            .withId('e-1')
            .under(const ConflictPolicy.manualReview())
            .queuedAt(Harness.noon)
            .build(),
      );

      await harness.drain(());

      expect(
        (await harness.blocked()).single.blockedReason,
        contains('newer write exists'),
      );
    });
  });

  group('a store that cannot be trusted', () {
    test('stops the drain and reports it', () async {
      // Everything else here is "not yet". A store that cannot be read is a
      // queue that cannot be trusted to remember, and writing into one is how
      // work disappears quietly.
      await harness.seed(entry('e-1'));
      harness.store.failNextWith(const OutboxUnavailable(detail: 'locked'));

      final drained = await harness.drain(());

      expect(drained.isFailure, isTrue);
      expect(harness.transport.received, isEmpty);
    });
  });

  group('the batch limit', () {
    test('works through one batch and asks to be called again', () async {
      harness = Harness(batchSize: 2);
      for (final id in ['a', 'b', 'c']) {
        await harness.seed(entry(id));
      }

      final status = unwrap(await harness.drain(()));

      expect(harness.transport.accepted, 2);
      expect(status, const SyncStatus.draining(pending: 1));
    });
  });

  group('blocked entries', () {
    test('are never attempted', () async {
      await harness.seed(
        OutboxEntryBuilder()
            .withId('e-1')
            .queuedAt(Harness.noon)
            .blocked('rejected')
            .build(),
      );

      await harness.drain(());

      expect(harness.transport.received, isEmpty);
    });
  });
}
