@Tags(['unit'])
library;

import 'package:sync_api/sync_api.dart';
import 'package:sync_testing/sync_testing.dart';
import 'package:test/test.dart';

void main() {
  group('OutboxEntryBuilder', () {
    test('produces freshly queued work by default', () {
      final entry = OutboxEntryBuilder().build();

      expect(entry.attempts, 0);
      expect(entry.isBlocked, isFalse);
      expect(entry.isDueAt(OutboxEntryBuilder.defaultQueuedAt), isTrue);
    });

    test('reaches an attempted state by attempting, not by assignment', () {
      // The builder walks the entity's own methods. A builder that set
      // `attempts` and `nextAttemptAt` independently could produce three
      // attempts with nothing scheduled — a shape no drain creates, and a
      // fixture that makes a passing test meaningless.
      final at = OutboxEntryBuilder.defaultQueuedAt;
      final entry = OutboxEntryBuilder()
          .attempted(at: at, backoff: const Duration(seconds: 4))
          .attempted(at: at, backoff: const Duration(seconds: 8))
          .build();

      expect(entry.attempts, 2);
      expect(entry.nextAttemptAt, at.add(const Duration(seconds: 8)));
    });

    test('blocks after the attempts, keeping the first reason', () {
      final entry = OutboxEntryBuilder().blocked('rejected').build();

      expect(entry.blockedReason, 'rejected');
      expect(entry.isDueAt(OutboxEntryBuilder.defaultQueuedAt), isFalse);
    });

    test('carries the routing key and the policy it was given', () {
      final entry = OutboxEntryBuilder()
          .ofType('payments.collect')
          .under(const ConflictPolicy.manualReview())
          .build();

      expect(entry.type, 'payments.collect');
      expect(entry.policy, const ConflictPolicy.manualReview());
    });

    test('never reads a clock', () {
      // Rule A1. Two entries built a moment apart are the same entry, which is
      // what makes a suite that builds a hundred of them reproducible.
      expect(
        OutboxEntryBuilder().build().queuedAt,
        OutboxEntryBuilder().build().queuedAt,
      );
    });
  });

  group('FakeClockSkew', () {
    test('reports what it was told', () async {
      final port = FakeClockSkew(skew: const Duration(minutes: 3));

      expect(
        (await port.skew()).fold((d) => d, (f) => throw StateError('$f')),
        const Duration(minutes: 3),
      );
    });

    test('can fail, because an offline device cannot ask', () async {
      final port = FakeClockSkew()..failsWith(const SyncOffline());

      expect((await port.skew()).isFailure, isTrue);
    });

    test('recovers when a new skew is set', () async {
      final port = FakeClockSkew()
        ..failsWith(const SyncOffline())
        ..reports(const Duration(seconds: 30));

      expect((await port.skew()).isSuccess, isTrue);
    });
  });

  group('FakeCommandTransport', () {
    test('records every envelope, retries included', () async {
      final transport = FakeCommandTransport();
      final entry = OutboxEntryBuilder().withId('e-1').build();

      await transport.send(entry.envelopeFor(cursor: SyncCursor.beginning));
      await transport.send(
        entry
            .attempted(
              at: OutboxEntryBuilder.defaultQueuedAt,
              backoff: const Duration(seconds: 1),
            )
            .envelopeFor(cursor: SyncCursor.beginning),
      );

      // Two envelopes arrived, one piece of work landed. "How many times did
      // this reach the server?" and "how much work did it do?" are different
      // questions, and an idempotency assertion needs both.
      expect(transport.received, hasLength(2));
      expect(transport.accepted, 1);
    });

    test('fails one routing key while the others keep landing', () async {
      final transport = FakeCommandTransport()
        ..failEveryTypeOf('payments.collect', const SyncOffline());

      final stuck = OutboxEntryBuilder()
          .withId('e-1')
          .ofType('payments.collect')
          .build();
      final fine = OutboxEntryBuilder()
          .withId('e-2')
          .ofType('delivery.completeAttempt')
          .build();

      expect(
        (await transport.send(
          stuck.envelopeFor(cursor: SyncCursor.beginning),
        )).isFailure,
        isTrue,
      );
      expect(
        (await transport.send(
          fine.envelopeFor(cursor: SyncCursor.beginning),
        )).isSuccess,
        isTrue,
      );
    });
  });
}
