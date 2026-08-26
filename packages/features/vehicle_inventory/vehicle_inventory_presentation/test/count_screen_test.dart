@Tags(['widget'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identity_api/identity_api.dart';
import 'package:shipments_api/shipments_api.dart';
import 'package:vehicle_inventory_api/vehicle_inventory_api.dart';
import 'package:vehicle_inventory_presentation/vehicle_inventory_presentation.dart';

ShipmentId _parcel(String raw) =>
    (ShipmentId.parse(raw) as Success<ShipmentId, ShipmentFailure>).value;

LoadCountId _countId(String raw) =>
    (LoadCountId.parse(raw) as Success<LoadCountId, VehicleInventoryFailure>)
        .value;

ActorId get _courier =>
    (ActorId.parse('courier-7') as Success<ActorId, IdentityFailure>).value;

/// A `VehicleInventoryFacade` this test steers.
///
/// It really holds a `LoadCount` and really applies the entity's rules, so the
/// screen is tested against the arithmetic it will meet in an app rather than
/// against a script.
final class _Inventory implements VehicleInventoryFacade {
  LoadCount? current;

  /// Set to fail the next call, whatever it is.
  VehicleInventoryFailure? failWith;

  @override
  Future<Result<LoadCount, VehicleInventoryFailure>> startCount({
    required ActorId courier,
    required LoadDirection direction,
  }) async {
    final failure = _taken();
    if (failure != null) {
      return Failed(failure);
    }
    final opened = LoadCount.opened(
      id: _countId('CNT-1'),
      courier: courier,
      direction: direction,
      manifest: {_parcel('SHP-1'), _parcel('SHP-2')},
      startedAt: DateTime.utc(2026, 3, 4, 6, 30),
    );
    if (opened case Success(:final value)) {
      current = value;
    }
    return opened;
  }

  @override
  Future<Result<LoadCount, VehicleInventoryFailure>> scan({
    required LoadCountId count,
    required ShipmentId shipment,
  }) async {
    final failure = _taken();
    if (failure != null) {
      return Failed(failure);
    }
    final scanned = current!.scan(shipment);
    if (scanned case Success(:final value)) {
      current = value;
    }
    return scanned;
  }

  @override
  Future<Result<LoadCount, VehicleInventoryFailure>> close(
    LoadCountId count,
  ) async {
    final closed = current!.closedAtInstant(DateTime.utc(2026, 3, 4, 7));
    if (closed case Success(:final value)) {
      current = value;
    }
    return closed;
  }

  @override
  Future<Result<LoadCount?, VehicleInventoryFailure>> openCountFor(
    ActorId courier,
  ) async {
    final failure = _taken();
    if (failure != null) {
      return Failed(failure);
    }
    final open = current;
    return Success(open != null && open.isOpen ? open : null);
  }

  VehicleInventoryFailure? _taken() {
    final failure = failWith;
    failWith = null;
    return failure;
  }
}

Widget _wrap(Widget child) =>
    Directionality(textDirection: TextDirection.ltr, child: child);

void main() {
  late _Inventory inventory;
  late CountController controller;

  setUp(() {
    inventory = _Inventory();
    controller = CountController(inventory: inventory, courier: _courier);
    addTearDown(controller.dispose);
  });

  testWidgets('a fresh screen is idle', (tester) async {
    await tester.pumpWidget(_wrap(CountScreen(controller: controller)));
    await controller.resume();
    await tester.pumpAndSettle();

    expect(find.text('inventory.idle'), findsOneWidget);
  });

  testWidgets('a started count shows how much of the van is counted', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(CountScreen(controller: controller)));
    await controller.start(LoadDirection.loading);
    await tester.pumpAndSettle();

    expect(find.text('0/2'), findsOneWidget);
    expect(find.text('inventory.missing 2'), findsOneWidget);
  });

  testWidgets('a scan moves the numbers', (tester) async {
    await tester.pumpWidget(_wrap(CountScreen(controller: controller)));
    await controller.start(LoadDirection.loading);
    await controller.scan(_parcel('SHP-1'));
    await tester.pumpAndSettle();

    expect(find.text('1/2'), findsOneWidget);
    expect(find.text('inventory.missing 1'), findsOneWidget);
  });

  testWidgets('a parcel nobody expected is shown as well as counted', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(CountScreen(controller: controller)));
    await controller.start(LoadDirection.loading);
    await controller.scan(_parcel('SHP-9'));
    await tester.pumpAndSettle();

    expect(find.text('inventory.unexpected 1'), findsOneWidget);
  });

  testWidgets('a reconciled close says so', (tester) async {
    await tester.pumpWidget(_wrap(CountScreen(controller: controller)));
    await controller.start(LoadDirection.loading);
    await controller.scan(_parcel('SHP-1'));
    await controller.scan(_parcel('SHP-2'));
    await controller.close();
    await tester.pumpAndSettle();

    expect(find.text('inventory.reconciled'), findsOneWidget);
  });

  testWidgets('a failure is rendered as a sentence, not a type name', (
    tester,
  ) async {
    inventory.failWith = const ManifestUnavailable();

    await tester.pumpWidget(_wrap(CountScreen(controller: controller)));
    await controller.start(LoadDirection.loading);
    await tester.pumpAndSettle();

    expect(find.text('The load list could not be reached.'), findsOneWidget);
  });

  test('a scan before a count has started is ignored', () async {
    await controller.scan(_parcel('SHP-1'));

    expect(controller.state, isA<CountIdle>());
    expect(inventory.current, isNull);
  });

  test('resume picks up a count that was left open', () async {
    await controller.start(LoadDirection.loading);
    final resumed = CountController(inventory: inventory, courier: _courier);
    addTearDown(resumed.dispose);

    await resumed.resume();

    expect(resumed.state, isA<CountInProgress>());
  });
}
