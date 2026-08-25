@Tags(['widget'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identity_api/identity_api.dart';
import 'package:identity_testing/identity_testing.dart';
import 'package:shipments_api/shipments_api.dart';
import 'package:shipments_presentation_courier/shipments_presentation_courier.dart';

/// A `SessionReader` over one fixed session, or none.
final class _Session implements SessionReader {
  _Session(this.current);

  @override
  final Session? current;

  @override
  Stream<Session?> changes() => Stream.value(current);
}

/// A `ShipmentsFacade` that answers `manifestFor` with whatever it was given.
final class _Facade implements ShipmentsFacade {
  _Facade(this._answer);

  final Result<List<ShipmentSummary>, ShipmentFailure> _answer;

  /// How many times the manifest was asked for.
  int asked = 0;

  @override
  Future<Result<List<ShipmentSummary>, ShipmentFailure>> manifestFor(
    ActorId courier,
  ) async {
    asked++;
    return _answer;
  }

  /// Every other method of the port, which this test does not use.
  ///
  /// A stub rather than eleven `UnimplementedError` overrides. What it says is
  /// "this test is about one method"; a call to any other one throws, which is
  /// louder than an override returning a plausible empty value.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final courier = SessionBuilder().build();

  List<ShipmentSummary> rows() => [
    ShipmentSummary(
      id: 'ship-1',
      barcode: '100000000007',
      status: ShipmentStatus.outForDelivery(courier.actor.id),
      consigneeName: 'Ayse Yilmaz',
      address: 'Bagdat Cd. 100',
    ),
  ];

  Widget screen(CourierManifestController controller) => Directionality(
    textDirection: TextDirection.ltr,
    child: CourierManifestScreen(controller: controller),
  );

  testWidgets('renders the stops the facade returned', (tester) async {
    final controller = CourierManifestController(
      shipments: _Facade(Success(rows())),
      session: _Session(courier),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(screen(controller));
    await tester.pumpAndSettle();

    expect(find.text('Ayse Yilmaz'), findsOneWidget);
    expect(find.text('outForDelivery'), findsOneWidget);
  });

  testWidgets('an empty manifest is an ordinary morning, not an error', (
    tester,
  ) async {
    // Showing an error here would have couriers calling the depot before
    // their first parcel of the day.
    final controller = CourierManifestController(
      shipments: _Facade(const Success([])),
      session: _Session(courier),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(screen(controller));
    await tester.pumpAndSettle();

    expect(find.text('Nothing assigned yet'), findsOneWidget);
  });

  testWidgets('a failure renders something a courier can act on', (
    tester,
  ) async {
    final controller = CourierManifestController(
      shipments: _Facade(const Failed(ShipmentsUnavailable())),
      session: _Session(courier),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(screen(controller));
    await tester.pumpAndSettle();

    expect(find.textContaining('No signal'), findsOneWidget);
  });

  test('nobody signed in means nothing is asked for', () async {
    // A screen behind a session guard should never reach this, and asking for
    // "nobody's manifest" would be a request the operation has to answer with
    // an error the user cannot act on.
    final facade = _Facade(Success(rows()));
    final controller = CourierManifestController(
      shipments: facade,
      session: _Session(null),
    );
    addTearDown(controller.dispose);

    await controller.load();

    expect(facade.asked, 0);
    expect(controller.state, isA<ManifestIdle>());
  });

  test('the two presentation packages publish different routes', () {
    // Scenario 7 in the route table: one feature, two driving adapters, two
    // different surfaces. The courier's routes are guarded by
    // viewAssignedShipments and the dispatcher's by viewAllShipments.
    const routes = ShipmentsCourierRoutes();

    expect(routes.moduleName, 'shipments.courier');
    expect(
      routes.routes.map((route) => route.requiredPermission),
      everyElement('viewAssignedShipments'),
    );
    expect(
      routes.routes.every((route) => route.requiresSession),
      isTrue,
    );
  });
}
