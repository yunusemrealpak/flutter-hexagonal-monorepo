@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:delivery_api/delivery_api.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  group('DeliveryAttempt', () {
    test('starts in progress, settled by nothing', () {
      final attempt = Fixtures.attempt();

      expect(attempt.outcome, isA<AttemptInProgress>());
      expect(attempt.isSettled, isFalse);
      expect(attempt.settledAt, isNull);
      expect(attempt.proofReference, isNull);
    });

    test(
      'completing carries the proof and the reference it was stored under',
      () {
        final settled = Fixtures.unwrap(
          Fixtures.attempt().completeWith(
            proof: Fixtures.proof(signature: Fixtures.signature()),
            reference: Fixtures.reference(),
            at: Fixtures.noon,
          ),
        );

        expect(settled.isSettled, isTrue);
        expect(settled.proofReference!.value, 'proof-1');
        expect(settled.outcome, isA<AttemptCompleted>());
      },
    );

    test('the entity applies the policy even when a use case already did', () {
      // Not a duplicated rule. A use case checks first to avoid paying for a
      // store it will refuse; the entity checks because an entity that trusts
      // its caller is not a guardian of anything.
      final refused = Fixtures.attempt(grade: DeliveryGrade.highValue)
          .completeWith(
            proof: Fixtures.proof(signature: Fixtures.signature()),
            reference: Fixtures.reference(),
            at: Fixtures.noon,
          );

      expect(
        (refused as Failed<DeliveryAttempt, DeliveryFailure>).failure,
        isA<ProofInsufficient>(),
      );
    });

    test('an attempt settles once, whoever asks the second time', () {
      // What stops a double tap on a slow screen becoming two deliveries, and
      // a replayed queue entry becoming a second one.
      final settled = Fixtures.unwrap(
        Fixtures.attempt().completeWith(
          proof: Fixtures.proof(photo: Fixtures.photo()),
          reference: Fixtures.reference(),
          at: Fixtures.noon,
        ),
      );

      final again = settled.completeWith(
        proof: Fixtures.proof(photo: Fixtures.photo()),
        reference: Fixtures.reference('proof-2'),
        at: Fixtures.noon,
      );

      expect(
        (again as Failed<DeliveryAttempt, DeliveryFailure>).failure,
        isA<AttemptAlreadySettled>(),
      );
    });

    test('a completed attempt cannot then be failed', () {
      final settled = Fixtures.unwrap(
        Fixtures.attempt().completeWith(
          proof: Fixtures.proof(photo: Fixtures.photo()),
          reference: Fixtures.reference(),
          at: Fixtures.noon,
        ),
      );

      expect(
        settled.failWith(
          reason: const NonDeliveryReason.recipientAbsent(),
          at: Fixtures.noon,
        ),
        isA<Failed<DeliveryAttempt, DeliveryFailure>>(),
      );
    });

    test('failing needs no evidence and no policy', () {
      // A visit that did not end in a hand-over has nothing to be sufficient.
      final failed = Fixtures.unwrap(
        Fixtures.attempt(grade: DeliveryGrade.highValue).failWith(
          reason: const NonDeliveryReason.recipientAbsent(),
          at: Fixtures.noon,
        ),
      );

      expect(failed.outcome, isA<AttemptFailed>());
      expect(failed.proofReference, isNull);
      expect(failed.settledAt, Fixtures.noon);
    });

    test('two attempts on the same shipment are two entities', () {
      // Nobody home on Tuesday and delivered on Wednesday is two rows, and an
      // operation asked about a complaint needs both.
      final tuesday = Fixtures.attempt();
      final wednesday = DeliveryAttempt.started(
        id: Fixtures.attemptId('attempt-2'),
        shipment: Fixtures.shipment(),
        courier: Fixtures.courier(),
        startedAt: Fixtures.noon.add(const Duration(days: 1)),
      );

      expect(tuesday, isNot(wednesday));
    });

    test('a settled attempt is still the same visit', () {
      // Equality is by identifier, which is what Entity is for: the record of
      // an afternoon does not become a different record when it closes.
      final attempt = Fixtures.attempt();
      final settled = Fixtures.unwrap(
        attempt.failWith(
          reason: const NonDeliveryReason.recipientAbsent(),
          at: Fixtures.noon,
        ),
      );

      expect(settled, attempt);
    });
  });

  group('NonDeliveryReason', () {
    test('says whether sending the courier back is worth it', () {
      // Behaviour on the union rather than a switch in whoever asks. Two
      // copies would disagree the first time a case was added.
      expect(const NonDeliveryReason.recipientAbsent().isRetryable, isTrue);
      expect(const NonDeliveryReason.accessDenied().isRetryable, isTrue);
      expect(
        NonDeliveryReason.rescheduled(
          requestedFor: Fixtures.noon,
        ).isRetryable,
        isTrue,
      );
      expect(const NonDeliveryReason.addressNotFound().isRetryable, isFalse);
      expect(const NonDeliveryReason.refusedByRecipient().isRetryable, isFalse);
      expect(
        const NonDeliveryReason.damagedInTransit(note: 'crushed').isRetryable,
        isFalse,
      );
    });
  });
}
