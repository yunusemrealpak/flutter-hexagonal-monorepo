@Tags(['unit'])
library;

import 'package:delivery_api/delivery_api.dart';
import 'package:delivery_testing/delivery_testing.dart';
import 'package:test/test.dart';

void main() {
  // The kit this package publishes, run against the fake it publishes beside
  // it. That the fake passes the same suite as the two real adapters is what
  // makes it evidence that the kit is about correctness rather than about one
  // implementation's habits.
  runProofStoreContract(FakeProofStore.new);

  group('FakeDeliveryGateway', () {
    test('keeps every attempt on a shipment, oldest first', () async {
      final gateway = FakeDeliveryGateway();

      await gateway.submit(DeliveryFixtures.failed());
      await gateway.submit(DeliveryFixtures.completed(id: 'attempt-2'));

      final rows = await gateway.attemptsFor('SHP-1');
      expect(rows.fold((r) => r.length, (f) => throw StateError('$f')), 2);
    });

    test('a resent attempt replaces itself rather than stacking', () async {
      // The identifier is what makes an attempt one visit. A gateway that
      // appended would make a retry look like a second delivery.
      final gateway = FakeDeliveryGateway();

      await gateway.submit(DeliveryFixtures.attempt());
      await gateway.submit(DeliveryFixtures.completed());

      final rows = await gateway.attemptsFor('SHP-1');
      final stored = rows.fold((r) => r, (f) => throw StateError('$f'));
      expect(stored, hasLength(1));
      expect(stored.single.isSettled, isTrue);
    });

    test('a shipment nobody has visited is empty, not failed', () async {
      final rows = await FakeDeliveryGateway().attemptsFor('SHP-9');

      expect(rows.fold((r) => r, (f) => throw StateError('$f')), isEmpty);
    });
  });

  group('FakeGeoFence', () {
    test('puts the courier at the door by default', () async {
      final verdict = await FakeGeoFence().locate('SHP-1');

      expect(
        verdict.fold((v) => v.isInside, (f) => throw StateError('$f')),
        isTrue,
      );
    });

    test('reports the distance when the courier is not there', () async {
      final fence = FakeGeoFence()..standAt(450);

      final verdict = await fence.locate('SHP-1');
      final answer = verdict.fold((v) => v, (f) => throw StateError('$f'));

      expect(answer.isInside, isFalse);
      expect(answer.metresAway, 450);
    });

    test('a position it cannot read is a failure, not a distance', () async {
      // "I cannot see where you are" and "you are three streets away" call for
      // different things from a courier.
      final fence = FakeGeoFence()
        ..failNextWith(const DeliveryPositionUnavailable(detail: 'no fix'));

      final verdict = await fence.locate('SHP-1');

      expect(
        verdict.fold((_) => null, (f) => f),
        isA<DeliveryPositionUnavailable>(),
      );
    });
  });

  group('FakeMediaCompressor', () {
    test('leaves a photograph that already fits untouched', () async {
      final photo = DeliveryFixtures.photo(bytes: const [1, 2]);

      final result = await FakeMediaCompressor().compress(
        photo,
        limitBytes: 10,
      );

      expect(result.fold((p) => p, (f) => throw StateError('$f')), same(photo));
    });

    test('brings a photograph under the limit', () async {
      final photo = DeliveryFixtures.photo(bytes: const [1, 2, 3, 4, 5, 6]);

      final result = await FakeMediaCompressor().compress(
        photo,
        limitBytes: 2,
      );

      expect(
        result.fold((p) => p.byteCount, (f) => throw StateError('$f')),
        2,
      );
    });

    test('refuses instead of passing the problem on', () async {
      // An adapter that returned the original anyway would move the failure to
      // the transport, hours later, on a device with no signal.
      final compressor = FakeMediaCompressor()..refuses = true;

      final result = await compressor.compress(
        DeliveryFixtures.photo(),
        limitBytes: 1,
      );

      expect(result.fold((_) => null, (f) => f), isA<MediaTooLarge>());
    });
  });
}
