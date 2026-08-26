@Tags(['unit'])
library;

import 'package:core_ports/core_ports.dart';
import 'package:sync_api/sync_api.dart';
import 'package:sync_testing/sync_testing.dart';
import 'package:test/test.dart';

import 'support/harness.dart';

void main() {
  late Harness harness;

  setUp(() => harness = Harness());
  tearDown(() => harness.coordinator.dispose());

  group('SyncCoordinator', () {
    test('queueing goes through the use case', () async {
      final queued = unwrap(
        await harness.coordinator.enqueue(const TestSyncCommand()),
      );

      expect(await harness.pending(), [queued]);
    });

    test('defaults to the policy that keeps the device\u2019s work', () async {
      // lastWriteWins resends rather than dropping or blocking. A feature that
      // has not thought about conflicts should get the option that keeps what
      // the courier did.
      final queued = unwrap(
        await harness.coordinator.enqueue(const TestSyncCommand()),
      );

      expect(queued.policy, const ConflictPolicy.lastWriteWins());
    });

    test('a subscriber hears the state at the moment it subscribes', () async {
      await harness.coordinator.enqueue(const TestSyncCommand());

      final first = await harness.coordinator.statusChanges().first;

      expect(first, const SyncStatus.draining(pending: 1));
    });

    test('a subscriber hears the queue change', () async {
      final seen = <SyncStatus>[];
      final subscription = harness.coordinator.statusChanges().listen(seen.add);
      await Future<void>.delayed(Duration.zero);

      await harness.coordinator.enqueue(const TestSyncCommand());
      await harness.coordinator.drain();
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(seen.first, const SyncStatus.idle());
      expect(seen.last, const SyncStatus.idle());
      expect(seen, contains(const SyncStatus.draining(pending: 1)));
    });

    test('adds no rule of its own to a refused enqueue', () async {
      harness.store.failNextWith(const OutboxUnavailable());

      final queued = await harness.coordinator.enqueue(const TestSyncCommand());

      expect(queued.isFailure, isTrue);
    });
  });

  group('the review queue', () {
    Future<OutboxEntry> blockOne() async {
      harness.transport.failEveryTypeOf(
        'test.write',
        const SyncRejected(reason: 'unknown shipment'),
      );
      await harness.seed(
        OutboxEntryBuilder().withId('e-1').queuedAt(Harness.noon).build(),
      );
      await harness.drain(());
      harness.transport.recover('test.write');
      return (await harness.blocked()).single;
    }

    test('lists what the queue gave up on', () async {
      final blocked = await blockOne();

      final queue = unwrap(await harness.coordinator.awaitingReview());

      expect(queue, [blocked]);
    });

    test('putting an entry back makes it due again', () async {
      final blocked = await blockOne();

      final resolved = unwrap(await harness.coordinator.retry(blocked.id));

      expect(resolved.isBlocked, isFalse);
      expect(resolved.isDueAt(harness.clock.now()), isTrue);
      expect(unwrap(await harness.coordinator.awaitingReview()), isEmpty);
    });

    test('keeps the attempts it already used', () async {
      // Resetting the count would hand a permanently broken command another
      // full budget of retries every time somebody pressed the button, which
      // is how it becomes a permanent load on the server.
      final blocked = await blockOne();

      final resolved = unwrap(await harness.coordinator.retry(blocked.id));

      expect(resolved.attempts, blocked.attempts);
    });

    test('the entry drains on the next pass', () async {
      final blocked = await blockOne();
      await harness.coordinator.retry(blocked.id);

      await harness.coordinator.drain();

      expect(harness.transport.accepted, 1);
      expect(await harness.pending(), isEmpty);
    });

    test('resolving something that is not blocked changes nothing', () async {
      // Two people looking at the same review queue is the ordinary case.
      // Reporting the second press as an error would say the queue is broken
      // when it is merely already fixed.
      final queued = unwrap(
        await harness.coordinator.enqueue(const TestSyncCommand()),
      );

      final resolved = unwrap(await harness.coordinator.retry(queued.id));

      expect(resolved, queued);
      expect(resolved.attempts, 0);
    });

    test('reports an identifier the store does not hold', () async {
      final missing = unwrap(OutboxEntryId.parse('nope'));

      expect((await harness.coordinator.retry(missing)).isFailure, isTrue);
    });
  });

  group('ReadSyncStatus', () {
    test('an empty queue is idle', () async {
      expect(unwrap(await harness.readStatus(())), const SyncStatus.idle());
    });

    test('work a person has to see outranks having no signal', () async {
      // A product decision rather than an obvious one: "two of these need you"
      // outranks "you are in a basement", because the second resolves itself
      // and the first does not.
      harness = Harness(connection: NetworkCondition.offline);
      await harness.seed(
        OutboxEntryBuilder()
            .withId('e-1')
            .queuedAt(Harness.noon)
            .blocked('rejected')
            .build(),
      );

      expect(
        unwrap(await harness.readStatus(())),
        const SyncStatus.blocked(pending: 0, needingReview: 1),
      );
    });

    test(
      'reports the earliest instant the queue has something to do',
      () async {
        await harness.seed(
          OutboxEntryBuilder()
              .withId('later')
              .queuedAt(Harness.noon)
              .attempted(at: Harness.noon, backoff: const Duration(minutes: 5))
              .build(),
        );
        await harness.seed(
          OutboxEntryBuilder()
              .withId('sooner')
              .queuedAt(Harness.noon)
              .attempted(at: Harness.noon, backoff: const Duration(minutes: 1))
              .build(),
        );

        expect(
          unwrap(await harness.readStatus(())),
          SyncStatus.waitingToRetry(
            pending: 2,
            nextAttemptAt: Harness.noon.add(const Duration(minutes: 1)),
          ),
        );
      },
    );
  });
}
