import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';
import 'package:shipments_api/shipments_api.dart';
import 'package:test/test.dart';

import 'shipment_builder.dart';

/// The behaviour every `ShipmentGateway` has to have, whatever is behind it.
///
/// Call it from a test in any package that ships an implementation:
///
/// ```dart
/// void main() {
///   runShipmentGatewayContract(InMemoryShipmentGateway.new);
/// }
/// ```
///
/// The same suite runs against the in-memory fake here and against
/// `RestShipmentGateway` in `shipments_infrastructure`. That is what stops a
/// fake and the adapter it stands in for drifting apart — the failure a
/// hand-written fake is otherwise guaranteed to produce, because nothing
/// checks that "what the fake does" is still "what the real one does", and the
/// tests that trusted the fake go on passing while production breaks.
///
/// **What belongs in a contract kit, and what does not.** Only behaviour
/// reachable through the port. Seeding happens through [ShipmentGateway.save]
/// rather than through a back door, because a back door is something only one
/// implementation has and the suite would stop being runnable against the
/// other. Transport failures are not here for the same reason: there is no way
/// to provoke one through the port, so they belong to each implementation's
/// own tests.
///
/// [createGateway] must return a *fresh, empty* gateway on every call. The
/// suite calls it once per test, and a gateway shared between tests makes the
/// order they run in part of the result.
void runShipmentGatewayContract(ShipmentGateway Function() createGateway) {
  group('ShipmentGateway contract', () {
    late ShipmentGateway gateway;

    final courier = ActorId.parse('courier-1').fold(
      (id) => id,
      (failure) => throw StateError('$failure'),
    );
    final other = ActorId.parse('courier-2').fold(
      (id) => id,
      (failure) => throw StateError('$failure'),
    );

    setUp(() => gateway = createGateway());

    Future<Shipment> save(Shipment shipment) async {
      final saved = await gateway.save(shipment);
      expect(saved.isSuccess, isTrue, reason: 'setup failed: $saved');
      return shipment;
    }

    group('byId', () {
      test('returns what was saved under that identifier', () async {
        final shipment = await save(ShipmentBuilder().withId('ship-1').build());

        expect(
          await gateway.byId(shipment.id),
          Success<Shipment, ShipmentFailure>(shipment),
        );
      });

      test('reports the identifier it could not find', () async {
        final missing = ShipmentId.parse('nope').fold(
          (id) => id,
          (failure) => throw StateError('$failure'),
        );

        expect(
          await gateway.byId(missing),
          Failed<Shipment, ShipmentFailure>(ShipmentNotFound(missing)),
        );
      });

      test(
        'returns the state as it was last saved, not as it started',
        () async {
          // The assertion that catches an implementation which persists an
          // identifier and rebuilds the rest from defaults.
          await save(ShipmentBuilder().withId('ship-1').build());
          final moved = await save(
            ShipmentBuilder()
                .withId('ship-1')
                .assignedTo(courier)
                .loaded()
                .build(),
          );

          final read = await gateway.byId(moved.id);
          expect(
            read.fold(
              (shipment) => shipment.status,
              (f) => throw StateError('$f'),
            ),
            ShipmentStatus.loadedOnVehicle(courier),
          );
        },
      );

      test('preserves the barcode and the consignee', () async {
        final shipment = await save(
          ShipmentBuilder()
              .withId('ship-1')
              .withBarcodeBody('38294756103')
              .to('Mehmet Demir', address: 'Ataturk Cd. 5, Izmir')
              .build(),
        );

        final read = await gateway.byId(shipment.id);
        final stored = read.fold((s) => s, (f) => throw StateError('$f'));

        expect(stored.barcode, shipment.barcode);
        expect(stored.consignee.name, 'Mehmet Demir');
        expect(stored.consignee.address.formatted, 'Ataturk Cd. 5, Izmir');
      });
    });

    group('save', () {
      test('returns the shipment it stored', () async {
        final shipment = ShipmentBuilder().withId('ship-1').build();

        expect(
          await gateway.save(shipment),
          Success<Shipment, ShipmentFailure>(shipment),
        );
      });

      test('is an upsert: saving an unknown shipment creates it', () async {
        final shipment = ShipmentBuilder().withId('brand-new').build();

        expect((await gateway.save(shipment)).isSuccess, isTrue);
        expect((await gateway.byId(shipment.id)).isSuccess, isTrue);
      });
    });

    group('resolve', () {
      test('returns the identifier the barcode belongs to', () async {
        final shipment = await save(
          ShipmentBuilder()
              .withId('ship-1')
              .withBarcodeBody('38294756103')
              .build(),
        );

        expect(
          await gateway.resolve(shipment.barcode),
          Success<ShipmentId, ShipmentFailure>(shipment.id),
        );
      });

      test('reports a well-formed barcode that names nothing', () async {
        await save(ShipmentBuilder().withId('ship-1').build());
        final stranger = Barcode.parse(
          '99999999999${Barcode.checkDigitFor('99999999999')}',
        ).fold((code) => code, (failure) => throw StateError('$failure'));

        expect(
          await gateway.resolve(stranger),
          Failed<ShipmentId, ShipmentFailure>(
            BarcodeNotRecognised(stranger.value),
          ),
        );
      });
    });

    group('manifestFor', () {
      test('returns only the shipments on that courier', () async {
        await save(
          ShipmentBuilder().withId('mine').assignedTo(courier).build(),
        );
        await save(
          ShipmentBuilder()
              .withId('theirs')
              .withBarcodeBody('38294756103')
              .assignedTo(other)
              .build(),
        );
        await save(ShipmentBuilder().withId('unassigned').build());

        final manifest = await gateway.manifestFor(courier.value);
        final rows = manifest.fold((r) => r, (f) => throw StateError('$f'));

        expect(rows.map((row) => row.id), ['mine']);
      });

      test(
        'is empty rather than a failure for a courier with nothing',
        () async {
          // "Nothing assigned to you" is an ordinary morning, not an error. An
          // implementation that failed here would put an error banner on a
          // courier's screen before their first assignment of the day.
          final manifest = await gateway.manifestFor(courier.value);

          expect(
            manifest.fold((rows) => rows, (f) => throw StateError('$f')),
            isEmpty,
          );
        },
      );

      test('carries the current state on every row', () async {
        await save(
          ShipmentBuilder()
              .withId('mine')
              .assignedTo(courier)
              .loaded()
              .outForDelivery()
              .build(),
        );

        final manifest = await gateway.manifestFor(courier.value);
        final rows = manifest.fold((r) => r, (f) => throw StateError('$f'));

        expect(rows.single.status, ShipmentStatus.outForDelivery(courier));
      });

      test('drops a shipment from the manifest once it is delivered', () async {
        // A delivered shipment is on nobody's manifest, and the state union is
        // where that is decided — ShipmentDeliveredToConsignee carries no
        // courier. This asserts the implementation reads it from there rather
        // than keeping a courier column of its own.
        await save(
          ShipmentBuilder()
              .withId('mine')
              .assignedTo(courier)
              .loaded()
              .outForDelivery()
              .delivered()
              .build(),
        );

        final manifest = await gateway.manifestFor(courier.value);

        expect(
          manifest.fold((rows) => rows, (f) => throw StateError('$f')),
          isEmpty,
        );
      });
    });

    group('the port never throws', () {
      test('every method reports failure as a Failed instead', () async {
        // Invariant 1.2.9. An implementation that threw would satisfy every
        // assertion above and still break the first caller that relied on the
        // return type telling the whole story.
        final missing = ShipmentId.parse('nope').fold(
          (id) => id,
          (failure) => throw StateError('$failure'),
        );
        final stranger = Barcode.parse(
          '99999999999${Barcode.checkDigitFor('99999999999')}',
        ).fold((code) => code, (failure) => throw StateError('$failure'));

        expect((await gateway.byId(missing)).isFailure, isTrue);
        expect((await gateway.resolve(stranger)).isFailure, isTrue);
        expect((await gateway.manifestFor('nobody')).isSuccess, isTrue);
      });
    });
  });
}
