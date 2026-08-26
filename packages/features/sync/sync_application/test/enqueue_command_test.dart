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

  group('EnqueueCommand', () {
    test('writes the work down and returns the entry', () async {
      final queued = unwrap(
        await harness.enqueue((
          command: const TestSyncCommand(type: 'delivery.completeAttempt'),
          policy: const ConflictPolicy.lastWriteWins(),
        )),
      );

      expect(queued.type, 'delivery.completeAttempt');
      expect(await harness.pending(), [queued]);
    });

    test('never attempts delivery', () async {
      // The property the whole feature stands on. A courier in a basement gets
      // the same answer as one in a yard with five bars, because the queue's
      // job starts after this returns.
      await harness.enqueue((
        command: const TestSyncCommand(),
        policy: const ConflictPolicy.lastWriteWins(),
      ));

      expect(harness.transport.received, isEmpty);
    });

    test('takes the identifier from the port, not from a counter', () async {
      // Rule A3. The identifier is also the handle the server de-duplicates
      // on, so a test that could not predict it could not assert anything
      // about idempotency either.
      final queued = unwrap(
        await harness.enqueue((
          command: const TestSyncCommand(),
          policy: const ConflictPolicy.lastWriteWins(),
        )),
      );

      expect(queued.id.value, 'entry-1');
    });

    test('takes the instant from the clock, not from DateTime.now', () async {
      // Rule A1.
      final queued = unwrap(
        await harness.enqueue((
          command: const TestSyncCommand(),
          policy: const ConflictPolicy.lastWriteWins(),
        )),
      );

      expect(queued.queuedAt, Harness.noon);
    });

    test('carries the policy the caller chose', () async {
      final queued = unwrap(
        await harness.enqueue((
          command: const TestSyncCommand(),
          policy: const ConflictPolicy.manualReview(),
        )),
      );

      expect(queued.policy, const ConflictPolicy.manualReview());
    });

    test('reports a store that could not write', () async {
      // The one failure a caller genuinely has to hear about: everything else
      // in this feature is "not yet", and this is "the device could not write
      // it down".
      harness.store.failNextWith(const OutboxUnavailable(detail: 'locked'));

      final queued = await harness.enqueue((
        command: const TestSyncCommand(),
        policy: const ConflictPolicy.lastWriteWins(),
      ));

      expect(queued.isFailure, isTrue);
      expect(harness.logger.recordsAt(LogLevel.error), hasLength(1));
    });

    test('two enqueues produce two distinct entries', () async {
      await harness.enqueue((
        command: const TestSyncCommand(),
        policy: const ConflictPolicy.lastWriteWins(),
      ));
      await harness.enqueue((
        command: const TestSyncCommand(),
        policy: const ConflictPolicy.lastWriteWins(),
      ));

      expect(await harness.pending(), hasLength(2));
    });
  });
}
