@Tags(['unit'])
library;

import 'package:sync_api/sync_api.dart';
import 'package:sync_testing/sync_testing.dart';
import 'package:test/test.dart';

void main() {
  group('FakeSyncFacade', () {
    late FakeSyncFacade queue;

    setUp(() {
      queue = FakeSyncFacade();
      addTearDown(queue.dispose);
    });

    test('records the routing key and keeps the command', () async {
      await queue.enqueue(const TestSyncCommand(type: 'delivery.done'));

      expect(queue.types, ['delivery.done']);
      expect(queue.queued.single, isA<TestSyncCommand>());
    });

    test('records the policy the caller chose', () async {
      // The policy is a domain decision made by the feature that queued the
      // work, so a test about that decision has to be able to see it.
      await queue.enqueue(
        const TestSyncCommand(),
        policy: const ConflictPolicy.manualReview(),
      );

      expect(queue.policies.single, isA<ManualReview>());
    });

    test('hands back an entry with the command on it', () async {
      final entry = await queue.enqueue(
        const TestSyncCommand(type: 'payments.collect'),
      );

      expect(
        entry.fold((e) => e.type, (f) => throw StateError('$f')),
        'payments.collect',
      );
    });

    test('every entry gets its own identifier', () async {
      final first = await queue.enqueue(const TestSyncCommand());
      final second = await queue.enqueue(const TestSyncCommand());

      expect(
        first.fold((e) => e.id, (f) => throw StateError('$f')),
        isNot(second.fold((e) => e.id, (f) => throw StateError('$f'))),
      );
    });

    test('enqueueing does not drain', () async {
      // The port's promise. A fake that delivered eagerly would let a caller
      // depend on something the real queue never does.
      await queue.enqueue(const TestSyncCommand());

      final status = await queue.drain();
      expect(
        status.fold((s) => s, (f) => throw StateError('$f')),
        isA<SyncDraining>(),
      );
    });

    test('reports a refusal the caller has to handle', () async {
      queue.failNextWith(const OutboxUnavailable(detail: 'locked'));

      final result = await queue.enqueue(const TestSyncCommand());

      expect(result.fold((_) => null, (f) => f), isA<OutboxUnavailable>());
      expect(queue.queued, isEmpty);
    });
  });
}
