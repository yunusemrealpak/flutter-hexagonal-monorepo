@Tags(['unit'])
library;

import 'dart:convert';

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

  group('FailWithReason', () {
    test('settles the attempt and queues the write', () async {
      final settled = (await harness.fail((
        attempt: DeliveryFixtures.attempt(),
        reason: const NonDeliveryReason.recipientAbsent(),
      ))).fold((value) => value, (failure) => throw StateError('$failure'));

      expect(settled.outcome, isA<AttemptFailed>());
      expect(harness.queue.types, ['delivery.failAttempt']);
    });

    test('publishes no event', () async {
      // Not an oversight. Nothing in the product subscribes to a failed
      // delivery yet, and an event published for a listener that does not
      // exist is a guess about the future that later has to be honoured.
      await harness.fail((
        attempt: DeliveryFixtures.attempt(),
        reason: const NonDeliveryReason.addressNotFound(found: 'a car park'),
      ));

      expect(harness.events.published, isEmpty);
    });

    test('refuses an attempt that has already settled', () async {
      final refused = await harness.fail((
        attempt: DeliveryFixtures.completed(),
        reason: const NonDeliveryReason.recipientAbsent(),
      ));

      expect(
        (refused as Failed<DeliveryAttempt, DeliveryFailure>).failure,
        isA<AttemptAlreadySettled>(),
      );
      expect(harness.queue.queued, isEmpty);
    });

    test('a queue that refuses is reported rather than swallowed', () async {
      harness.queue.failNextWith(const SyncOffline());

      final refused = await harness.fail((
        attempt: DeliveryFixtures.attempt(),
        reason: const NonDeliveryReason.recipientAbsent(),
      ));

      expect(
        (refused as Failed<DeliveryAttempt, DeliveryFailure>).failure,
        isA<DeliveryUnavailable>(),
      );
    });
  });

  group('AttemptReads', () {
    test('hands the gateway a raw identifier', () async {
      await harness.gateway.submit(DeliveryFixtures.failed());

      final rows = await harness.reads(DeliveryFixtures.shipment());

      expect(
        rows.fold((r) => r.length, (f) => throw StateError('$f')),
        1,
      );
    });

    test('a parcel nobody has visited reads as empty, not failed', () async {
      final rows = await harness.reads(DeliveryFixtures.shipment('SHP-9'));

      expect(rows.fold((r) => r, (f) => throw StateError('$f')), isEmpty);
    });
  });

  group('the three coordinators', () {
    test('announces an attempt it opened', () async {
      final seen = <DeliveryAttempt>[];
      harness.history.changes().listen(seen.add);

      await harness.execution.startAttempt(
        shipment: DeliveryFixtures.shipment(),
        courier: DeliveryFixtures.courier(),
      );
      await Future<void>.delayed(Duration.zero);

      expect(seen, hasLength(1));
    });

    test('announces nothing for a call it refused', () async {
      // The record did not change, and a screen that redrew on it would
      // flicker for no reason.
      harness.fence.standAt(900);

      final seen = <DeliveryAttempt>[];
      harness.history.changes().listen(seen.add);

      await harness.execution.startAttempt(
        shipment: DeliveryFixtures.shipment(),
        courier: DeliveryFixtures.courier(),
      );
      await Future<void>.delayed(Duration.zero);

      expect(seen, isEmpty);
    });

    test('an attempt settled by one role reaches the reader', () async {
      // The reason `DeliveryChannel` exists. `changes()` is declared on
      // `DeliveryHistory`, and a settlement — which a desk performs and a
      // courier performs — has to reach a screen holding that interface.
      final opened = (await harness.execution.startAttempt(
        shipment: DeliveryFixtures.shipment(),
        courier: DeliveryFixtures.courier(),
      )).fold((a) => a, (f) => throw StateError('$f'));

      final seen = <DeliveryAttempt>[];
      harness.history.changes().listen(seen.add);

      await harness.settlement.failWithReason(
        attempt: opened,
        reason: const NonDeliveryReason.recipientAbsent(),
      );
      await Future<void>.delayed(Duration.zero);

      expect(seen, hasLength(1));
    });

    test('reads go straight through without an announcement', () async {
      final seen = <DeliveryAttempt>[];
      harness.history.changes().listen(seen.add);

      await harness.history.attemptsFor(DeliveryFixtures.shipment());
      await Future<void>.delayed(Duration.zero);

      expect(seen, isEmpty);
    });
  });

  group('the commands sync carries', () {
    Map<String, Object?> bodyOf(SyncCommand command) =>
        jsonDecode(command.payload) as Map<String, Object?>;

    test('a completed delivery carries the handle, not the bytes', () async {
      // The assertion that would fail if somebody put a base64 signature in
      // the payload. An outbox row is a TEXT column on a device that may be
      // holding a day's work.
      final command = CompleteDeliveryCommand(
        DeliveryFixtures.completed(proof: DeliveryFixtures.fullProof()),
      );

      final body = bodyOf(command);
      expect(body['proofReference'], 'proof-1');
      expect(body['evidence'], ['photo', 'signature']);
      expect(command.payload, isNot(contains('bytes')));
    });

    test('a completed delivery carries the identifier a server dedupes on', () {
      final body = bodyOf(
        CompleteDeliveryCommand(DeliveryFixtures.completed()),
      );

      expect(body['attemptId'], 'attempt-1');
      expect(body['shipmentId'], 'SHP-1');
      expect(body['courierId'], 'courier-1');
    });

    test('a failed delivery flattens its reason into data', () {
      // sync stores a string, so the union has to become data somewhere, and
      // this is the only place that knows what the cases mean.
      final body = bodyOf(
        FailDeliveryCommand(
          DeliveryFixtures.failed(
            reason: const NonDeliveryReason.damagedInTransit(note: 'crushed'),
          ),
        ),
      );

      expect(body['reason'], 'damagedInTransit');
      expect(body['note'], 'crushed');
      expect(body['retryable'], isFalse);
    });

    test('the two writes are two routing keys', () {
      // A failed delivery and a completed one reach different endpoints and
      // are retried under different rules. One command with an outcome field
      // would put a switch inside the transport handler.
      expect(
        CompleteDeliveryCommand(DeliveryFixtures.completed()).type,
        isNot(FailDeliveryCommand(DeliveryFixtures.failed()).type),
      );
    });
  });
}
