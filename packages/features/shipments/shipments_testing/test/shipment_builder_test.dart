@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';
import 'package:shipments_api/shipments_api.dart';
import 'package:shipments_testing/shipments_testing.dart';
import 'package:test/test.dart';

ActorId _courier([String raw = 'courier-1']) =>
    ActorId.parse(raw).fold((id) => id, (f) => throw StateError('$f'));

void main() {
  group('walks the machine rather than assembling a state', () {
    test('a built shipment carries the history of getting there', () {
      final shipment = ShipmentBuilder()
          .assignedTo(_courier())
          .loaded()
          .outForDelivery()
          .build();

      expect(shipment.status, ShipmentStatus.outForDelivery(_courier()));
      expect(shipment.history.map((move) => move.to.label), [
        'assignedToCourier',
        'loadedOnVehicle',
        'outForDelivery',
      ]);
    });

    test('refuses to build a state the machine cannot reach', () {
      // The whole reason the builder does not use Shipment's public
      // constructor. A fixture in an impossible state produces assertions
      // about a situation that never happens.
      expect(
        () => ShipmentBuilder().delivered().build(),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('invalidTransition'),
          ),
        ),
      );
    });

    test('says which call was missing when a courier is needed', () {
      expect(
        () => ShipmentBuilder().loaded().build(),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('assignedTo()'),
          ),
        ),
      );
    });
  });

  group('immutability', () {
    test('a shared prefix does not leak between two branches', () {
      final onTheVan = ShipmentBuilder().assignedTo(_courier()).loaded();

      final delivered = onTheVan.outForDelivery().delivered().build();
      final stillLoaded = onTheVan.build();

      expect(stillLoaded.status, ShipmentStatus.loadedOnVehicle(_courier()));
      expect(delivered.status.isTerminal, isTrue);
    });
  });

  group('defaults', () {
    test('the barcode it produces is one Barcode.parse accepts', () {
      final shipment = ShipmentBuilder().withBarcodeBody('38294756103').build();

      expect(Barcode.parse(shipment.barcode.value).isSuccess, isTrue);
    });

    test('every move is stamped with the fixed moment', () {
      final shipment = ShipmentBuilder().assignedTo(_courier()).build();

      expect(shipment.history.single.at, ShipmentBuilder.defaultMoment);
      expect(ShipmentBuilder.defaultMoment.isUtc, isTrue);
    });
  });

  group('the fakes can be told to fail', () {
    test(
      'a queued failure is returned once, then normal service resumes',
      () async {
        final gateway = InMemoryShipmentGateway()
          ..failNextWith(const ShipmentsUnavailable(detail: 'offline'));
        final shipment = ShipmentBuilder().build();

        expect(
          await gateway.save(shipment),
          const Failed<Shipment, ShipmentFailure>(
            ShipmentsUnavailable(detail: 'offline'),
          ),
        );
        expect((await gateway.save(shipment)).isSuccess, isTrue);
      },
    );
  });
}
