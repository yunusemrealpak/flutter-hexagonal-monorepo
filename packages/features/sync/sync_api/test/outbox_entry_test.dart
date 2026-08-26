@Tags(['unit'])
library;

import 'package:sync_api/sync_api.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  group('OutboxEntry.queued', () {
    test('takes the routing key and body from the command', () {
      final entry = queued(
        command: const TestCommand(
          type: 'delivery.completeAttempt',
          payload: '{"attempt":"a-1"}',
        ),
      );

      expect(entry.type, 'delivery.completeAttempt');
      expect(entry.payload, '{"attempt":"a-1"}');
    });

    test('starts with no attempts and nothing scheduled', () {
      final entry = queued();

      expect(entry.attempts, 0);
      expect(entry.lastAttemptAt, isNull);
      expect(entry.nextAttemptAt, isNull);
      expect(entry.isBlocked, isFalse);
    });

    test('is due immediately', () {
      expect(queued().isDueAt(noon), isTrue);
    });
  });

  group('identity', () {
    test('two entries with the same id are the same entry', () {
      // Equality by id, and it matters more here than anywhere else in the
      // workspace: the identifier is also the handle the server de-duplicates
      // on, so "same entry" and "same piece of work" have to be one statement.
      final first = queued();
      final second = queued().attempted(
        at: noon,
        backoff: const Duration(seconds: 5),
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    test('two entries with different ids are not', () {
      expect(queued(), isNot(queued(id: 'entry-2')));
    });
  });

  group('attempted', () {
    test('counts the attempt and schedules the next one', () {
      final entry = queued().attempted(
        at: noon,
        backoff: const Duration(seconds: 30),
      );

      expect(entry.attempts, 1);
      expect(entry.lastAttemptAt, noon);
      expect(entry.nextAttemptAt, noon.add(const Duration(seconds: 30)));
    });

    test('is not due until the backoff has passed', () {
      final entry = queued().attempted(
        at: noon,
        backoff: const Duration(seconds: 30),
      );

      expect(entry.isDueAt(noon.add(const Duration(seconds: 29))), isFalse);
      expect(entry.isDueAt(noon.add(const Duration(seconds: 30))), isTrue);
    });

    test('accumulates across attempts', () {
      final entry = queued()
          .attempted(at: noon, backoff: const Duration(seconds: 1))
          .attempted(at: noon, backoff: const Duration(seconds: 2))
          .attempted(at: noon, backoff: const Duration(seconds: 4));

      expect(entry.attempts, 3);
      expect(entry.nextAttemptAt, noon.add(const Duration(seconds: 4)));
    });

    test('leaves the original untouched', () {
      final original = queued();
      final moved = original.attempted(
        at: noon,
        backoff: const Duration(seconds: 1),
      );

      expect(original.attempts, 0);
      expect(moved.attempts, 1);
    });
  });

  group('blocked', () {
    test('records why, and stops being due', () {
      final entry = queued().blocked('server rejected: unknown shipment');

      expect(entry.isBlocked, isTrue);
      expect(entry.blockedReason, 'server rejected: unknown shipment');
      expect(entry.isDueAt(noon.add(const Duration(days: 1))), isFalse);
    });

    test('keeps the first reason when blocked twice', () {
      // The first explanation describes what happened; the later ones are
      // consequences of it. Overwriting would leave a person reading "attempt
      // limit reached" for an entry that was rejected outright.
      final entry = queued()
          .blocked('rejected: unknown shipment')
          .blocked(
            'attempt limit reached',
          );

      expect(entry.blockedReason, 'rejected: unknown shipment');
    });

    test('is skipped rather than removed', () {
      // A blocked entry keeps its payload. Dropping it would destroy the
      // evidence of a delivery the operation still has to reconcile.
      final entry = queued().blocked('needs a person');

      expect(entry.payload, isNotEmpty);
    });
  });

  group('unblocked', () {
    test('puts the entry back in the queue, keeping the attempt count', () {
      final entry = queued()
          .attempted(at: noon, backoff: const Duration(minutes: 5))
          .blocked('rejected')
          .unblocked();

      expect(entry.isBlocked, isFalse);
      expect(entry.attempts, 1);
      expect(entry.isDueAt(noon), isTrue, reason: 'the backoff is cleared too');
    });
  });

  group('envelopeFor', () {
    test('numbers the attempt from one', () {
      final envelope = queued().envelopeFor(cursor: SyncCursor.beginning);

      expect(envelope.attempt, 1);
    });

    test('numbers a retry as the attempt it actually is', () {
      final envelope = queued()
          .attempted(at: noon, backoff: const Duration(seconds: 1))
          .envelopeFor(cursor: SyncCursor.beginning);

      expect(envelope.attempt, 2);
    });

    test('corrects the queued instant into the server frame', () {
      // The device's clock is a minute behind, so the work happened a minute
      // later than the device thinks. Correcting `now` instead would leave two
      // devices' last-write-wins decided by whose clock drifted further.
      final envelope = queued().envelopeFor(
        cursor: const SyncCursor('c-9'),
        clockSkew: const Duration(minutes: 1),
      );

      expect(envelope.queuedAt, noon.add(const Duration(minutes: 1)));
    });

    test('carries the policy the feature chose', () {
      final envelope = queued(
        policy: const ConflictPolicy.manualReview(),
      ).envelopeFor(cursor: SyncCursor.beginning);

      expect(envelope.policy, const ConflictPolicy.manualReview());
    });

    test('two envelopes for the same attempt are equal', () {
      // A SyncEnvelope is generated, and structural equality is what a value
      // that has no identity of its own is supposed to have.
      expect(
        queued().envelopeFor(cursor: const SyncCursor('c-1')),
        queued().envelopeFor(cursor: const SyncCursor('c-1')),
      );
    });
  });
}
