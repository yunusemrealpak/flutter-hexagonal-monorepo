@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:payments_api/payments_api.dart';
import 'package:payments_testing/payments_testing.dart';
import 'package:shipments_api/shipments_api.dart';
import 'package:shipments_application/shipments_application.dart';
import 'package:shipments_testing/shipments_testing.dart';
import 'package:test/test.dart';

import 'support/harness.dart';

void main() {
  late Harness harness;
  final courier = Harness.courier();

  setUp(() => harness = Harness());

  Shipment seed(ShipmentBuilder builder) {
    final shipment = builder.build();
    harness.gateway.seed(shipment);
    return shipment;
  }

  group('the entity decides, the use case orchestrates', () {
    test('a legal move is applied, saved and cached', () async {
      final shipment = seed(ShipmentBuilder().withId('ship-1'));

      final result = await harness.advanceShipment(
        AssignToCourier(id: shipment.id, courier: courier),
      );

      expect(
        Harness.unwrap(result).status,
        ShipmentStatus.assignedToCourier(courier),
      );
      expect(harness.gateway.stored.single.status.courier, courier);
      expect(harness.cache.length, 1);
    });

    test('a refused move changes nothing anywhere', () async {
      final shipment = seed(ShipmentBuilder().withId('ship-1'));

      final result = await harness.advanceShipment(
        CompleteDelivery(id: shipment.id, proofReference: 'proof-1'),
      );

      expect(
        result,
        const Failed<Shipment, ShipmentFailure>(
          InvalidTransition(
            from: 'awaitingAssignment',
            to: 'deliveredToConsignee',
          ),
        ),
      );
      expect(harness.gateway.stored.single.status, shipment.status);
      expect(harness.cache.length, 0, reason: 'nothing was cached');
      expect(harness.events.published, isEmpty);
    });

    test(
      'a shipment that does not exist fails before any transition',
      () async {
        final missing = Harness.unwrap(ShipmentId.parse('nope'));

        expect(
          await harness.advanceShipment(
            AssignToCourier(id: missing, courier: courier),
          ),
          Failed<Shipment, ShipmentFailure>(ShipmentNotFound(missing)),
        );
      },
    );
  });

  group('the clock is a port, not a call', () {
    test('the transition is stamped with the injected instant', () async {
      final shipment = seed(
        ShipmentBuilder().withId('ship-1').assignedTo(courier).loaded(),
      );

      final result = await harness.advanceShipment(
        StartDelivery(id: shipment.id, courier: courier),
      );

      expect(Harness.unwrap(result).history.last.at, Harness.now);
    });

    test('a caller cannot decide when a delivery happened', () async {
      // CompleteDelivery carries a proof reference and no timestamp. The only
      // way `at` gets a value is the Clock port inside the use case, which is
      // why no test in this suite can produce a delivery two hours ago by
      // asking for one.
      final shipment = seed(
        ShipmentBuilder()
            .withId('ship-1')
            .assignedTo(courier)
            .loaded()
            .outForDelivery(),
      );

      final result = await harness.advanceShipment(
        CompleteDelivery(id: shipment.id, proofReference: 'proof-1'),
      );

      expect(
        Harness.unwrap(result).status,
        ShipmentStatus.deliveredToConsignee(
          proofReference: 'proof-1',
          at: Harness.now,
        ),
      );
    });
  });

  group('domain events', () {
    test('a delivery is published for whoever is listening', () async {
      // Scenario 2. payments_application closes the matching collection when
      // it sees this; neither package knows the other exists.
      final shipment = seed(
        ShipmentBuilder()
            .withId('ship-1')
            .assignedTo(courier)
            .loaded()
            .outForDelivery(),
      );

      await harness.advanceShipment(
        CompleteDelivery(id: shipment.id, proofReference: 'proof-7'),
      );

      final published = harness.events.publishedOf<ShipmentDelivered>().single;
      expect(published.shipmentId, shipment.id);
      expect(published.proofReference, 'proof-7');
      expect(published.occurredAt, Harness.now);
    });

    test('a failed attempt and a return are published too', () async {
      final failed = seed(
        ShipmentBuilder()
            .withId('ship-1')
            .assignedTo(courier)
            .loaded()
            .outForDelivery(),
      );
      await harness.advanceShipment(
        FailDelivery(id: failed.id, reason: 'nobody home'),
      );

      final returning = seed(
        ShipmentBuilder()
            .withId('ship-2')
            .withBarcodeBody('38294756103')
            .assignedTo(courier)
            .loaded()
            .outForDelivery(),
      );
      await harness.advanceShipment(ReturnToDepot(id: returning.id));

      expect(harness.events.publishedOf<ShipmentFailed>(), hasLength(1));
      expect(harness.events.publishedOf<ShipmentReturned>(), hasLength(1));
    });

    test('the quiet moves publish nothing', () async {
      // An event per transition would be a bus carrying six times the traffic
      // for symmetry's sake, with every subscriber filtering five of them out.
      final shipment = seed(ShipmentBuilder().withId('ship-1'));

      await harness.advanceShipment(
        AssignToCourier(id: shipment.id, courier: courier),
      );
      await harness.advanceShipment(
        LoadOntoVehicle(id: shipment.id, courier: courier),
      );

      expect(harness.events.published, isEmpty);
    });
  });

  group('the payment guard — scenario 1', () {
    Shipment atTheDoor() => seed(
      ShipmentBuilder()
          .withId('ship-1')
          .assignedTo(courier)
          .loaded()
          .outForDelivery(),
    );

    test('a hand-over is refused while money is still owed', () async {
      // shipments_application reaches payments_api's PaymentStatusReader, and
      // payments_api names shipments_api in return. Two features that need
      // each other, and no cycle: contracts depend on no implementation.
      final shipment = atTheDoor();
      harness.payments.owes('ship-1', PaymentsFixtures.lira(4500));

      final refused = await harness.advanceShipment(
        CompleteDelivery(id: shipment.id, proofReference: 'proof-7'),
      );

      expect(
        (refused as Failed<Shipment, ShipmentFailure>).failure,
        isA<PaymentOutstanding>(),
      );
      expect(
        harness.gateway.stored.single.status,
        isA<ShipmentOutForDelivery>(),
        reason: 'the shipment must not have moved',
      );
      expect(harness.events.published, isEmpty);
    });

    test('the refusal says which parcel and how much', () async {
      // Shipments' own failure, carrying a string. Money is a payments type
      // and section 2.1 keeps a foreign model out of this vocabulary.
      final shipment = atTheDoor();
      harness.payments.owes('ship-1', PaymentsFixtures.lira(4500));

      final refused = await harness.advanceShipment(
        CompleteDelivery(id: shipment.id, proofReference: 'proof-7'),
      );

      final failure =
          (refused as Failed<Shipment, ShipmentFailure>).failure
              as PaymentOutstanding;
      expect(failure.shipment, 'ship-1');
      expect(failure.amount, contains('4500'));
    });

    test('a prepaid parcel is handed over without a word', () async {
      final shipment = atTheDoor();

      final delivered = await harness.advanceShipment(
        CompleteDelivery(id: shipment.id, proofReference: 'proof-7'),
      );

      expect(delivered, isA<Success<Shipment, ShipmentFailure>>());
      expect(harness.payments.asked, ['ship-1']);
    });

    test('nothing else asks payments anything', () async {
      // Assigning, loading and returning a parcel are things an operation does
      // to a shipment, and none is the moment money changes hands. Blocking
      // them on a collection would stop a depot moving parcels.
      final shipment = seed(ShipmentBuilder().withId('ship-1'));

      await harness.advanceShipment(
        AssignToCourier(id: shipment.id, courier: courier),
      );

      expect(harness.payments.asked, isEmpty);
    });

    test('an unreadable payment status does not strand a delivery', () async {
      // The parcel is at the door and the courier is standing there. Refusing
      // over a network would strand a delivery that has already happened; the
      // collection is reconciled afterwards, when payments sees the event.
      final shipment = atTheDoor();
      harness.payments.failNextWith(
        const PaymentsFailure.paymentsUnavailable(),
      );

      final delivered = await harness.advanceShipment(
        CompleteDelivery(id: shipment.id, proofReference: 'proof-7'),
      );

      expect(delivered, isA<Success<Shipment, ShipmentFailure>>());
      expect(harness.logger.records, isNotEmpty);
    });

    test('a settled collection does not block anything', () async {
      final shipment = atTheDoor();
      harness.payments.settled(
        'ship-1',
        PaymentsFixtures.lira(4500),
        Harness.now,
      );

      final delivered = await harness.advanceShipment(
        CompleteDelivery(id: shipment.id, proofReference: 'proof-7'),
      );

      expect(delivered, isA<Success<Shipment, ShipmentFailure>>());
    });
  });

  group('a failing cache is not a failing delivery', () {
    test('the move succeeds and the shortfall is logged', () async {
      final shipment = seed(
        ShipmentBuilder()
            .withId('ship-1')
            .assignedTo(courier)
            .loaded()
            .outForDelivery(),
      );
      harness.cache.failNextWith(const ShipmentsUnavailable(detail: 'full'));

      final result = await harness.advanceShipment(
        CompleteDelivery(id: shipment.id, proofReference: 'proof-1'),
      );

      // A shipment the operation has accepted is not un-accepted because this
      // device could not write it to disk. Failing here would turn a full disk
      // into a delivery that did not happen.
      expect(result.isSuccess, isTrue);
      expect(harness.events.publishedOf<ShipmentDelivered>(), hasLength(1));
      expect(
        harness.logger.records.map((record) => record.message),
        contains('shipment saved remotely but not cached'),
      );
    });

    test('a failing gateway does stop the move', () async {
      final shipment = seed(ShipmentBuilder().withId('ship-1'));
      harness.gateway
        ..failNextWith(const ShipmentsUnavailable())
        ..failNextWith(const ShipmentsUnavailable());

      final result = await harness.advanceShipment(
        AssignToCourier(id: shipment.id, courier: courier),
      );

      expect(result.isFailure, isTrue);
      expect(harness.events.published, isEmpty);
    });
  });
}
