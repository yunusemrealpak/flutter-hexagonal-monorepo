import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:test/test.dart';
import 'package:vehicle_inventory_api/vehicle_inventory_api.dart';

import 'support/harness.dart';

void main() {
  late InventoryHarness harness;

  setUp(() {
    harness = InventoryHarness()..depotSays(['SHP-1', 'SHP-2', 'SHP-3']);
  });

  Future<LoadCount> started() async => InventoryHarness.valueOf(
    await harness.facade.startCount(
      courier: InventoryHarness.courier,
      direction: LoadDirection.loading,
    ),
  );

  group('starting a count', () {
    test('opens it against the depot manifest', () async {
      final count = await started();

      expect(count.manifest, hasLength(3));
      expect(count.scanned, isEmpty);
      expect(count.startedAt, harness.clock.now());
    });

    test(
      'a manifest entry that is not an identifier fails the count',
      () async {
        harness = InventoryHarness()..depotSays(['SHP-1', '']);

        final started = await harness.facade.startCount(
          courier: InventoryHarness.courier,
          direction: LoadDirection.loading,
        );

        expect(InventoryHarness.failureOf(started), isA<MalformedCount>());
      },
    );
  });

  group('scanning', () {
    test('a parcel on the manifest leaves it', () async {
      final count = await started();

      final scanned = InventoryHarness.valueOf(
        await harness.facade.scan(
          count: count.id,
          shipment: InventoryHarness.parcel('SHP-1'),
        ),
      );

      expect(scanned.missing, hasLength(2));
    });

    test('a parcel nobody expected is recorded', () async {
      final count = await started();

      final scanned = InventoryHarness.valueOf(
        await harness.facade.scan(
          count: count.id,
          shipment: InventoryHarness.parcel('SHP-9'),
        ),
      );

      expect(scanned.unexpected, hasLength(1));
    });

    test('a double beep is one parcel', () async {
      final count = await started();
      await harness.facade.scan(
        count: count.id,
        shipment: InventoryHarness.parcel('SHP-1'),
      );

      final again = InventoryHarness.valueOf(
        await harness.facade.scan(
          count: count.id,
          shipment: InventoryHarness.parcel('SHP-1'),
        ),
      );

      expect(again.scanned, hasLength(1));
      expect(again.missing, hasLength(2));
    });

    test('a count that is not there is missing, not a fault', () async {
      await started();

      final scanned = await harness.facade.scan(
        count:
            (LoadCountId.parse('CNT-404')
                    as Success<LoadCountId, VehicleInventoryFailure>)
                .value,
        shipment: InventoryHarness.parcel('SHP-1'),
      );

      expect(InventoryHarness.failureOf(scanned), isA<CountMissing>());
    });
  });

  group('closing', () {
    test('a reconciled count closes quietly', () async {
      var count = await started();
      for (final id in ['SHP-1', 'SHP-2', 'SHP-3']) {
        count = InventoryHarness.valueOf(
          await harness.facade.scan(
            count: count.id,
            shipment: InventoryHarness.parcel(id),
          ),
        );
      }

      final closed = InventoryHarness.valueOf(
        await harness.facade.close(count.id),
      );

      expect(closed.isReconciled, isTrue);
      expect(harness.logger.recordsAt(LogLevel.warning), isEmpty);
    });

    test(
      'a count with parcels missing closes, and says so in the log',
      () async {
        final count = await started();

        final closed = InventoryHarness.valueOf(
          await harness.facade.close(count.id),
        );

        expect(closed.isOpen, isFalse);
        expect(closed.missing, hasLength(3));
        expect(harness.logger.recordsAt(LogLevel.warning), hasLength(1));
      },
    );

    test('a closed count is no longer the open one', () async {
      final count = await started();
      await harness.facade.close(count.id);

      final open = await harness.facade.openCountFor(InventoryHarness.courier);

      expect(
        (open as Success<LoadCount?, VehicleInventoryFailure>).value,
        isNull,
      );
    });
  });

  group('resuming', () {
    test('a courier who has not started counting has no open count', () async {
      final open = await harness.facade.openCountFor(InventoryHarness.courier);

      expect(
        (open as Success<LoadCount?, VehicleInventoryFailure>).value,
        isNull,
      );
    });

    test('the newest open count is the one handed back', () async {
      await started();
      harness.clock.advance(const Duration(hours: 8));
      harness.depotSays(['SHP-4']);
      final afternoon = await started();

      final open = await harness.facade.openCountFor(InventoryHarness.courier);

      expect(
        (open as Success<LoadCount?, VehicleInventoryFailure>).value?.id,
        afternoon.id,
      );
    });

    test('scans survive a re-read', () async {
      final count = await started();
      await harness.facade.scan(
        count: count.id,
        shipment: InventoryHarness.parcel('SHP-2'),
      );

      final open = await harness.facade.openCountFor(InventoryHarness.courier);

      expect(
        (open as Success<LoadCount?, VehicleInventoryFailure>).value?.scanned,
        {InventoryHarness.parcel('SHP-2')},
      );
    });
  });
}
