import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';
import 'package:shipments_api/shipments_api.dart';
import 'package:test/test.dart';

import 'shipment_builder.dart';

/// The behaviour every `ShipmentCache` has to have.
///
/// Shorter than the gateway's kit, and the difference between them is the
/// point: a cache miss is `Success(null)` and a gateway miss is a failure.
/// That distinction is the whole reason the two ports are separate rather than
/// one port with a flag, so it is the first thing this suite asserts.
///
/// [createCache] must return a fresh, empty cache on every call.
void runShipmentCacheContract(ShipmentCache Function() createCache) {
  group('ShipmentCache contract', () {
    late ShipmentCache cache;

    final courier = ActorId.parse('courier-1').fold(
      (id) => id,
      (failure) => throw StateError('$failure'),
    );

    setUp(() => cache = createCache());

    test('a miss is an empty success, not a failure', () async {
      final missing = ShipmentId.parse('nope').fold(
        (id) => id,
        (failure) => throw StateError('$failure'),
      );

      expect(
        await cache.byId(missing),
        const Success<Shipment?, ShipmentFailure>(null),
      );
    });

    test('reads back what was put in', () async {
      final shipment = ShipmentBuilder().withId('ship-1').build();
      await cache.put(shipment);

      expect(
        await cache.byId(shipment.id),
        Success<Shipment?, ShipmentFailure>(shipment),
      );
    });

    test('put replaces rather than accumulating', () async {
      await cache.put(ShipmentBuilder().withId('ship-1').build());
      final moved = ShipmentBuilder()
          .withId('ship-1')
          .assignedTo(courier)
          .build();
      await cache.put(moved);

      final read = await cache.byId(moved.id);
      expect(
        read.fold(
          (shipment) => shipment?.status,
          (f) => throw StateError('$f'),
        ),
        ShipmentStatus.assignedToCourier(courier),
      );
    });

    test('manifestFor returns only that courier, as summaries', () async {
      await cache.put(
        ShipmentBuilder().withId('mine').assignedTo(courier).build(),
      );
      await cache.put(ShipmentBuilder().withId('unassigned').build());

      final manifest = await cache.manifestFor(courier.value);
      final rows = manifest.fold((r) => r, (f) => throw StateError('$f'));

      expect(rows.map((row) => row.id), ['mine']);
    });

    test('clear empties it, and succeeds on an empty cache', () async {
      await cache.put(ShipmentBuilder().withId('ship-1').build());

      expect((await cache.clear()).isSuccess, isTrue);
      expect(
        await cache.byId(ShipmentBuilder().withId('ship-1').build().id),
        const Success<Shipment?, ShipmentFailure>(null),
      );
      expect(
        (await cache.clear()).isSuccess,
        isTrue,
        reason: 'clearing nothing is not a failure',
      );
    });
  });
}
