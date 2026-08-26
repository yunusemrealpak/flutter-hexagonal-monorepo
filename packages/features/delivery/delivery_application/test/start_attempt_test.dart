@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:delivery_api/delivery_api.dart';
import 'package:delivery_testing/delivery_testing.dart';
import 'package:test/test.dart';

import 'support/harness.dart';

void main() {
  late Harness harness;

  setUp(() {
    harness = Harness();
    addTearDown(harness.dispose);
  });

  Future<Result<DeliveryAttempt, DeliveryFailure>> start({
    DeliveryGrade grade = DeliveryGrade.standard,
  }) => harness.start((
    shipment: DeliveryFixtures.shipment(),
    courier: DeliveryFixtures.courier(),
    grade: grade,
  ));

  group('StartAttempt', () {
    test('opens an attempt when the courier is at the address', () async {
      final attempt = (await start()).fold(
        (value) => value,
        (failure) => throw StateError('$failure'),
      );

      expect(attempt.isSettled, isFalse);
      expect(attempt.shipment.value, 'SHP-1');
      expect(attempt.startedAt, DeliveryFixtures.noon);
    });

    test('asks the fence about the shipment, by raw identifier', () async {
      // The port's signature, and not an oversight: an adapter may see no
      // foreign _api, so a parameter typed ShipmentId would be one its own
      // adapter could not write down. Unwrapping here is the crossing being
      // done by the layer allowed to do it.
      await start();

      expect(harness.fence.asked, ['SHP-1']);
    });

    test('refuses from three streets away, and says how far', () async {
      // A delivery recorded from the wrong place is worse than no record: it
      // looks like evidence and is not.
      harness.fence.standAt(450);

      final refused = await start();

      final failure =
          (refused as Failed<DeliveryAttempt, DeliveryFailure>).failure
              as OutsideDeliveryArea;
      expect(failure.metresAway, 450);
      expect(failure.allowedMetres, 100);
    });

    test(
      'a position it cannot read is not the same as the wrong place',
      () async {
        // "I cannot see where you are" and "you are three streets away" send a
        // courier to different places. A use case that collapsed them would
        // either block every basement or accept deliveries from the depot.
        harness.fence.failNextWith(
          const DeliveryPositionUnavailable(detail: 'no fix'),
        );

        final refused = await start();

        expect(
          (refused as Failed<DeliveryAttempt, DeliveryFailure>).failure,
          isA<DeliveryPositionUnavailable>(),
        );
      },
    );

    test('mints exactly one identifier, from the port', () async {
      // The identifier is what a server de-duplicates on, so it is minted
      // once per intention rather than once per retry.
      await start();

      expect(harness.ids.issuedCount, 1);
    });

    test('two attempts on one shipment get two identifiers', () async {
      final first = (await start()).fold(
        (a) => a.id,
        (f) => throw StateError('$f'),
      );
      final second = (await start()).fold(
        (a) => a.id,
        (f) => throw StateError('$f'),
      );

      expect(first, isNot(second));
    });

    test('carries the grade it was told, not one it worked out', () async {
      // Delivery never reads a Shipment. What it needs to know about a parcel
      // is how much proof it is worth, and it is told in its own vocabulary.
      final attempt = (await start(grade: DeliveryGrade.highValue)).fold(
        (value) => value,
        (failure) => throw StateError('$failure'),
      );

      expect(attempt.grade, DeliveryGrade.highValue);
    });
  });
}
