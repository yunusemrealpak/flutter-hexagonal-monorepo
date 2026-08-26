@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:delivery_api/delivery_api.dart';
import 'package:delivery_application/delivery_application.dart';
import 'package:delivery_testing/delivery_testing.dart';
import 'package:sync_api/sync_api.dart';
import 'package:test/test.dart';

import 'support/harness.dart';

void main() {
  late Harness harness;

  setUp(() {
    harness = Harness();
    addTearDown(harness.dispose);
  });

  Future<Result<DeliveryAttempt, DeliveryFailure>> complete({
    DeliveryAttempt? attempt,
    ProofOfDelivery? proof,
  }) => harness.complete((
    attempt: attempt ?? DeliveryFixtures.attempt(),
    proof: proof ?? DeliveryFixtures.proof(),
  ));

  group('CompleteWithProof', () {
    test('stores the evidence, settles, queues and publishes', () async {
      final settled = (await complete()).fold(
        (value) => value,
        (failure) => throw StateError('$failure'),
      );

      expect(settled.isSettled, isTrue);
      expect(harness.store.references, hasLength(1));
      expect(harness.queue.types, ['delivery.completeAttempt']);
      expect(harness.events.publishedOf<DeliveryCompleted>(), hasLength(1));
    });

    test('the event carries the reference, never the evidence', () async {
      // The bytes stop at the proof store. The queue, the event and the server
      // all see a short string, which is what keeps a signature bitmap inside
      // this feature.
      await complete();

      final event = harness.events.publishedOf<DeliveryCompleted>().single;
      expect(event.proofReference, 'proof-1');
      expect(event.shipment.value, 'SHP-1');
      expect(event.courier.value, 'courier-1');
    });

    test('the event carries domain time, not publication time', () async {
      // When the hand-over happened, not when a subscriber heard about it.
      // The two are hours apart when a queue drains late.
      final settled = (await complete()).fold(
        (value) => value,
        (failure) => throw StateError('$failure'),
      );

      expect(
        harness.events.publishedOf<DeliveryCompleted>().single.occurredAt,
        settled.settledAt,
      );
    });

    test('checks the policy before it pays for a store write', () async {
      // The entity would refuse this too. Checking first is what stops a
      // high-value parcel closed without a photograph costing a write.
      final refused = await complete(
        attempt: DeliveryFixtures.attempt(grade: DeliveryGrade.highValue),
        proof: DeliveryFixtures.proof(signature: DeliveryFixtures.signature()),
      );

      expect(
        (refused as Failed<DeliveryAttempt, DeliveryFailure>).failure,
        isA<ProofInsufficient>(),
      );
      expect(harness.store.references, isEmpty);
      expect(harness.queue.queued, isEmpty);
    });

    test('refuses an attempt that has already settled', () async {
      // What stops a double tap on a slow screen becoming two deliveries.
      final refused = await complete(attempt: DeliveryFixtures.completed());

      expect(
        (refused as Failed<DeliveryAttempt, DeliveryFailure>).failure,
        isA<AttemptAlreadySettled>(),
      );
      expect(harness.queue.queued, isEmpty);
    });

    test('compresses a photograph against the app s limit', () async {
      harness.photoLimitBytes = 2;

      await complete(
        proof: DeliveryFixtures.proof(
          photo: DeliveryFixtures.photo(bytes: const [1, 2, 3, 4, 5, 6]),
        ),
      );

      expect(harness.compressor.limits, [2]);
    });

    test('stores the compressed photograph, not the original', () async {
      harness.photoLimitBytes = 2;

      final settled = (await complete(
        proof: DeliveryFixtures.proof(
          photo: DeliveryFixtures.photo(bytes: const [1, 2, 3, 4, 5, 6]),
        ),
      )).fold((value) => value, (failure) => throw StateError('$failure'));

      final outcome = settled.outcome as AttemptCompleted;
      expect(outcome.proof.photo!.byteCount, 2);
    });

    test('a proof with no photograph never reaches the compressor', () async {
      await complete(
        proof: DeliveryFixtures.proof(signature: DeliveryFixtures.signature()),
      );

      expect(harness.compressor.limits, isEmpty);
    });

    test('a photograph that will not fit stops the delivery here', () async {
      // Rather than sitting in an outbox on a device with no signal, which is
      // where the failure would otherwise surface.
      harness.compressor.refuses = true;

      final refused = await complete(
        proof: DeliveryFixtures.proof(photo: DeliveryFixtures.photo()),
      );

      expect(
        (refused as Failed<DeliveryAttempt, DeliveryFailure>).failure,
        isA<MediaTooLarge>(),
      );
      expect(harness.store.references, isEmpty);
    });

    test('a store that refuses queues nothing and publishes nothing', () async {
      harness.store.failNextWith(
        const ProofStoreUnavailable(detail: 'locked'),
      );

      final refused = await complete();

      expect(
        (refused as Failed<DeliveryAttempt, DeliveryFailure>).failure,
        isA<ProofStoreUnavailable>(),
      );
      expect(harness.queue.queued, isEmpty);
      expect(harness.events.published, isEmpty);
    });

    test(
      'a queue that refuses is reported, and nothing is published',
      () async {
        // The queue is the durable record. Reporting success would tell a
        // courier their afternoon is safe when the only copy is in memory, and
        // publishing would have payments react to a delivery nobody recorded.
        harness.queue.failNextWith(const OutboxUnavailable(detail: 'full'));

        final refused = await complete();

        expect(
          (refused as Failed<DeliveryAttempt, DeliveryFailure>).failure,
          isA<DeliveryUnavailable>(),
        );
        expect(harness.events.published, isEmpty);
      },
    );

    test('queues under lastWriteWins, on purpose', () async {
      // If the office marked this parcel undeliverable while the courier was
      // in a basement, the courier is the one who was at the door. Nothing is
      // destroyed by preferring their record.
      await complete();

      expect(harness.queue.policies.single, isA<LastWriteWins>());
    });

    test(
      'the queued command names delivery, and sync never decodes it',
      () async {
        await complete();

        final command = harness.queue.queued.single;
        expect(command, isA<CompleteDeliveryCommand>());
        expect(command.type, 'delivery.completeAttempt');
      },
    );
  });
}
