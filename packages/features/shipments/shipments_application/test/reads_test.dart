@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:shipments_api/shipments_api.dart';
import 'package:shipments_testing/shipments_testing.dart';
import 'package:test/test.dart';

import 'support/harness.dart';

void main() {
  late Harness harness;
  final courier = Harness.courier();

  setUp(() => harness = Harness());

  group('FindShipment prefers the network', () {
    test('reads from the gateway and writes through to the cache', () async {
      final shipment = ShipmentBuilder().withId('ship-1').build();
      harness.gateway.seed(shipment);

      expect(
        await harness.findShipment(shipment.id),
        Success<Shipment, ShipmentFailure>(shipment),
      );
      expect(harness.cache.length, 1);
    });

    test(
      'falls back to the cache when the gateway cannot be reached',
      () async {
        final shipment = ShipmentBuilder().withId('ship-1').build();
        await harness.cache.put(shipment);
        harness.gateway.failNextWith(const ShipmentsUnavailable());

        expect(
          await harness.findShipment(shipment.id),
          Success<Shipment, ShipmentFailure>(shipment),
        );
      },
    );

    test(
      'does not serve a cached copy of a shipment that does not exist',
      () async {
        // The narrow fallback. "Not found" is an answer, not a failure to
        // answer, and serving a cached copy of a cancelled parcel is how
        // it gets delivered anyway.
        final shipment = ShipmentBuilder().withId('ship-1').build();
        await harness.cache.put(shipment);

        expect(
          await harness.findShipment(shipment.id),
          Failed<Shipment, ShipmentFailure>(ShipmentNotFound(shipment.id)),
        );
      },
    );

    test('reports the network failure when the cache is empty too', () async {
      final shipment = ShipmentBuilder().withId('ship-1').build();
      harness.gateway.failNextWith(const ShipmentsUnavailable(detail: 'dns'));

      expect(
        await harness.findShipment(shipment.id),
        const Failed<Shipment, ShipmentFailure>(
          ShipmentsUnavailable(detail: 'dns'),
        ),
      );
    });

    test('reports the network failure when the cache is broken too', () async {
      // A broken cache is not a better answer than the network failure that
      // sent us to it; reporting the cache's failure would send somebody to
      // look at the wrong thing.
      final shipment = ShipmentBuilder().withId('ship-1').build();
      harness.gateway.failNextWith(const ShipmentsUnavailable(detail: 'dns'));
      harness.cache.failNextWith(const ShipmentsUnavailable(detail: 'disk'));

      expect(
        await harness.findShipment(shipment.id),
        const Failed<Shipment, ShipmentFailure>(
          ShipmentsUnavailable(detail: 'dns'),
        ),
      );
    });
  });

  group('LoadManifest', () {
    test('returns the courier rows the gateway knows about', () async {
      harness.gateway
        ..seed(ShipmentBuilder().withId('mine').assignedTo(courier).build())
        ..seed(ShipmentBuilder().withId('nobody').build());

      final page = Harness.unwrap(
        await harness.loadManifest((
          courier: courier,
          page: const PageRequest(),
        )),
      );

      expect(page.items.map((row) => row.id), ['mine']);
    });

    test(
      'falls back to what this device has when the network is gone',
      () async {
        await harness.cache.put(
          ShipmentBuilder().withId('mine').assignedTo(courier).build(),
        );
        harness.gateway.failNextWith(const ShipmentsUnavailable());

        final page = Harness.unwrap(
          await harness.loadManifest(
            (courier: courier, page: const PageRequest()),
          ),
        );

        expect(page.items.map((row) => row.id), ['mine']);
        // The cache is not paged, so what it answers is the last page there
        // is. Offering a cursor would invite a caller to ask for a second page
        // this device has no way to produce.
        expect(page.hasMore, isFalse);
      },
    );

    test('will not fall back part-way through a walk', () async {
      // A cursor is opaque to whoever did not produce it, so the gateway's
      // means nothing to the cache. Falling back here could only start the
      // cache from the beginning — serving rows the courier has already
      // scrolled past as if they were new — so the honest answer is the
      // failure, which the caller already knows how to show.
      await harness.cache.put(
        ShipmentBuilder().withId('mine').assignedTo(courier).build(),
      );
      harness.gateway.failNextWith(const ShipmentsUnavailable());

      final refused = await harness.loadManifest((
        courier: courier,
        page: const PageRequest(after: PageCursor('mine')),
      ));

      expect(refused.isFailure, isTrue);
    });

    test('an empty manifest is an ordinary morning, not a failure', () async {
      final page = Harness.unwrap(
        await harness.loadManifest((
          courier: courier,
          page: const PageRequest(),
        )),
      );

      expect(page.items, isEmpty);
      expect(page.hasMore, isFalse);
    });
  });

  group('ResolveBarcode', () {
    test('resolves through the port, then reads the shipment', () async {
      final shipment = ShipmentBuilder().withId('ship-1').build();
      harness.gateway.seed(shipment);
      harness.resolver.register(shipment.barcode, shipment.id);

      expect(
        await harness.resolveBarcode(shipment.barcode),
        Success<Shipment, ShipmentFailure>(shipment),
      );
      expect(harness.resolver.asked, [shipment.barcode]);
    });

    test('an unknown barcode never reaches the gateway', () async {
      final stranger = ShipmentBuilder().withBarcodeBody('38294756103').build();

      expect(
        await harness.resolveBarcode(stranger.barcode),
        Failed<Shipment, ShipmentFailure>(
          BarcodeNotRecognised(stranger.barcode.value),
        ),
      );
    });
  });

  group('ShipmentsCoordinator', () {
    test('emits on the change stream for a move that happened', () async {
      final shipment = ShipmentBuilder().withId('ship-1').build();
      harness.gateway.seed(shipment);

      final seen = <Shipment>[];
      final subscription = harness.coordinator.changes().listen(seen.add);
      addTearDown(subscription.cancel);

      await harness.coordinator.assign(id: shipment.id, courier: courier);
      await pumpEventQueue();

      expect(seen.single.status, ShipmentStatus.assignedToCourier(courier));
    });

    test('emits nothing for a move that was refused', () async {
      // A refused move did not change the shipment, and a screen that redrew
      // on it would flicker for no reason.
      final shipment = ShipmentBuilder().withId('ship-1').build();
      harness.gateway.seed(shipment);

      final seen = <Shipment>[];
      final subscription = harness.coordinator.changes().listen(seen.add);
      addTearDown(subscription.cancel);

      await harness.coordinator.completeDelivery(
        id: shipment.id,
        proofReference: 'proof-1',
      );
      await pumpEventQueue();

      expect(seen, isEmpty);
    });

    test('drives the whole happy path through the port', () async {
      final shipment = ShipmentBuilder().withId('ship-1').build();
      harness.gateway.seed(shipment);
      final facade = harness.coordinator;

      await facade.assign(id: shipment.id, courier: courier);
      await facade.loadOnto(id: shipment.id, courier: courier);
      await facade.startDelivery(id: shipment.id, courier: courier);
      final delivered = await facade.completeDelivery(
        id: shipment.id,
        proofReference: 'proof-1',
      );

      expect(Harness.unwrap(delivered).status.isTerminal, isTrue);
      expect(Harness.unwrap(delivered).history, hasLength(4));
    });
  });
}
