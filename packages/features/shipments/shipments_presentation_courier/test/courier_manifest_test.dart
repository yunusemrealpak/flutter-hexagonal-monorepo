@Tags(['widget'])
library;

import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:design_system/design_system.dart';
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
  _Facade(Result<PageOf<ShipmentSummary>, ShipmentFailure> answer)
    : _answers = [answer];

  /// Answers each page in turn, repeating the last one once they run out.
  _Facade.pages(this._answers);

  final List<Result<PageOf<ShipmentSummary>, ShipmentFailure>> _answers;

  /// How many times the manifest was asked for.
  int asked = 0;

  /// The page requests it was handed, oldest first.
  final List<PageRequest> requests = [];

  /// Completed by the test to hold a fetch open, when there is one.
  Completer<void>? gate;

  @override
  Future<Result<PageOf<ShipmentSummary>, ShipmentFailure>> manifestFor(
    ActorId courier, {
    PageRequest page = const PageRequest(),
  }) async {
    final index = asked;
    asked++;
    requests.add(page);
    if (gate case final gate?) await gate.future;
    return _answers[index < _answers.length ? index : _answers.length - 1];
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

  Widget screen(
    CourierManifestController controller, {
    void Function(ShipmentSummary)? onStopSelected,
  }) => PeykTheme.wrap(
    child: CourierManifestScreen(
      controller: controller,
      onStopSelected: onStopSelected,
    ),
  );

  ShipmentSummary row(String id) => ShipmentSummary(
    id: id,
    barcode: '100000000007',
    status: ShipmentStatus.outForDelivery(courier.actor.id),
    consigneeName: 'Consignee $id',
    address: 'Bagdat Cd. 100',
  );

  CourierManifestController over(_Facade facade) {
    final controller = CourierManifestController(
      shipments: facade,
      session: _Session(courier),
    );
    addTearDown(controller.dispose);
    return controller;
  }

  group('paging', () {
    test('asks for the page the last one said to resume from', () async {
      final facade = _Facade.pages([
        Success(PageOf(items: [row('a')], next: const PageCursor('a'))),
        Success(PageOf(items: [row('b')])),
      ]);
      final controller = over(facade);

      await controller.load();
      await controller.loadMore();

      expect(facade.requests.map((r) => r.after?.value), [null, 'a']);
    });

    test('appends the next page rather than replacing the list', () async {
      // The bug this is here for is a real one: a controller that emits the
      // page it just received leaves a courier looking at stops twenty-one to
      // forty with no way back to the first twenty.
      final facade = _Facade.pages([
        Success(PageOf(items: [row('a')], next: const PageCursor('a'))),
        Success(PageOf(items: [row('b')])),
      ]);
      final controller = over(facade);

      await controller.load();
      await controller.loadMore();

      final state = controller.state as ManifestReady;
      expect(state.rows.map((r) => r.id), ['a', 'b']);
      expect(state.hasMore, isFalse);
    });

    test('a page that fails keeps the rows already on screen', () async {
      final facade = _Facade.pages([
        Success(PageOf(items: [row('a')], next: const PageCursor('a'))),
        const Failed(ShipmentsUnavailable()),
      ]);
      final controller = over(facade);

      await controller.load();
      await controller.loadMore();

      // Dropping to `ManifestFailed` would take a courier's whole visible
      // round away because the twenty-first stop did not arrive.
      final state = controller.state as ManifestReady;
      expect(state.rows.map((r) => r.id), ['a']);
      expect(state.moreFailure, isA<ShipmentsUnavailable>());
      expect(state.hasMore, isTrue, reason: 'the page can be retried');
    });

    test('asks for nothing once the manifest has run out', () async {
      final facade = _Facade(Success(PageOf(items: [row('a')])));
      final controller = over(facade);

      await controller.load();
      await controller.loadMore();

      expect(facade.asked, 1);
    });

    test('will not fetch the same page twice in one gesture', () async {
      // A list that asks for more when it is scrolled asks several times in
      // the same swipe. Without the in-flight guard the second request is
      // issued from the same state as the first, the same page comes back
      // twice, and it is appended twice — duplicate stops on a round.
      final facade = _Facade.pages([
        Success(PageOf(items: [row('a')], next: const PageCursor('a'))),
        Success(PageOf(items: [row('b')])),
      ]);
      final controller = over(facade);
      await controller.load();

      facade.gate = Completer<void>();
      final first = controller.loadMore();
      final second = controller.loadMore();
      facade.gate!.complete();
      await Future.wait([first, second]);

      expect(facade.asked, 2, reason: 'one first page and one second');
      expect((controller.state as ManifestReady).rows.map((r) => r.id), [
        'a',
        'b',
      ]);
    });

    test('loading again starts the walk from the beginning', () async {
      final facade = _Facade.pages([
        Success(PageOf(items: [row('a')], next: const PageCursor('a'))),
        Success(PageOf(items: [row('b')])),
        Success(PageOf(items: [row('a')])),
      ]);
      final controller = over(facade);
      await controller.load();
      await controller.loadMore();

      await controller.load();

      expect(facade.requests.last.after, isNull);
      expect((controller.state as ManifestReady).rows.map((r) => r.id), ['a']);
    });
  });

  testWidgets('offers the next page when there is one', (tester) async {
    final controller = over(
      _Facade.pages([
        Success(PageOf(items: [row('a')], next: const PageCursor('a'))),
        Success(PageOf(items: [row('b')])),
      ]),
    );

    await tester.pumpWidget(screen(controller));
    await tester.pumpAndSettle();
    expect(find.text(ShipmentsCourierStrings.loadMore), findsOneWidget);

    await tester.tap(find.text(ShipmentsCourierStrings.loadMore));
    await tester.pumpAndSettle();

    expect(find.text('Consignee b'), findsOneWidget);
    // The affordance goes when the manifest runs out. A list that keeps
    // offering it teaches a courier that the button does nothing.
    expect(find.text(ShipmentsCourierStrings.loadMore), findsNothing);
  });

  testWidgets('renders the stops the facade returned', (tester) async {
    final controller = CourierManifestController(
      shipments: _Facade(Success(PageOf(items: rows()))),
      session: _Session(courier),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(screen(controller));
    await tester.pumpAndSettle();

    expect(find.text('Ayse Yilmaz'), findsOneWidget);
    expect(
      find.text(
        ShipmentsCourierStrings.status(
          ShipmentStatus.outForDelivery(courier.actor.id),
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('an empty manifest is an ordinary morning, not an error', (
    tester,
  ) async {
    // Showing an error here would have couriers calling the depot before
    // their first parcel of the day.
    final controller = CourierManifestController(
      shipments: _Facade(const Success(PageOf(items: []))),
      session: _Session(courier),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(screen(controller));
    await tester.pumpAndSettle();

    expect(find.text(ShipmentsCourierStrings.empty), findsOneWidget);
  });

  group('choosing a stop', () {
    testWidgets('reports the row, not a destination', (tester) async {
      final chosen = <ShipmentSummary>[];
      final controller = CourierManifestController(
        shipments: _Facade(Success(PageOf(items: rows()))),
        session: _Session(courier),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(screen(controller, onStopSelected: chosen.add));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ayse Yilmaz'));

      // A ShipmentSummary — this feature's own word. Where a stop leads is
      // the app's decision, and this package could not name it: it may not
      // import delivery_presentation. §2.4.
      expect(chosen.single.consigneeName, 'Ayse Yilmaz');
    });

    testWidgets('a list with nowhere to go does not respond', (tester) async {
      final controller = CourierManifestController(
        shipments: _Facade(Success(PageOf(items: rows()))),
        session: _Session(courier),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(screen(controller));
      await tester.pumpAndSettle();

      final row = tester.widget<PeykListRow>(find.byType(PeykListRow).first);
      expect(row.onTap, isNull);
    });
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

    expect(
      find.text(ShipmentsCourierStrings.failureUnavailable),
      findsOneWidget,
    );
  });

  test('nobody signed in means nothing is asked for', () async {
    // A screen behind a session guard should never reach this, and asking for
    // "nobody's manifest" would be a request the operation has to answer with
    // an error the user cannot act on.
    final facade = _Facade(Success(PageOf(items: rows())));
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

  // The mapping the design system deliberately cannot make, and the half of
  // scenario 7 that only two presentation packages can show: the courier's
  // screen and the dispatcher's board disagree about what undeliverable
  // means, because it means different things to the two people looking at it.
  // The visit is over and the parcel goes back — normal to a courier, and to a
  // dispatcher a parcel somebody has to do something about today.
  test('a delivered parcel is drawn as success', () {
    expect(
      CourierManifestScreen.intentOf(
        ShipmentStatus.deliveredToConsignee(
          at: DateTime.utc(2026, 3, 4),
          proofReference: 'proof-1',
        ),
      ),
      PeykIntent.success,
    );
  });

  test('an undeliverable parcel is a warning on a courier list', () {
    expect(
      CourierManifestScreen.intentOf(
        ShipmentStatus.undeliverable(
          at: DateTime.utc(2026, 3, 4),
          reason: 'nobody home',
        ),
      ),
      PeykIntent.warning,
    );
  });

  // The same seven the dispatcher package declares, and the reason both do:
  // section 2 forbids a presentation package from depending on another, so
  // sharing them means spelling them twice. This switch is what stops the two
  // drifting — adding a ShipmentStatus stops it compiling.
  test('every state has a key in the manifest', () {
    final instant = DateTime.utc(2026, 3, 4);
    final statuses = <ShipmentStatus>[
      const ShipmentStatus.awaitingAssignment(),
      ShipmentStatus.assignedToCourier(courier.actor.id),
      ShipmentStatus.loadedOnVehicle(courier.actor.id),
      ShipmentStatus.outForDelivery(courier.actor.id),
      ShipmentStatus.deliveredToConsignee(
        proofReference: 'proof-1',
        at: instant,
      ),
      ShipmentStatus.undeliverable(reason: 'nobody home', at: instant),
      ShipmentStatus.returnedToDepot(at: instant),
    ];

    for (final status in statuses) {
      expect(
        ShipmentsCourierStrings.statusKeys,
        contains(ShipmentsCourierStrings.status(status)),
      );
    }
    expect(ShipmentsCourierStrings.statusKeys, hasLength(statuses.length));
  });
}
