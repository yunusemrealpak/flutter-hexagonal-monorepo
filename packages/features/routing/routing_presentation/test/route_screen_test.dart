@Tags(['widget'])
library;

import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identity_api/identity_api.dart';
import 'package:routing_api/routing_api.dart';
import 'package:routing_presentation/routing_presentation.dart';
import 'package:routing_testing/routing_testing.dart';

/// A `RoutingFacade` this test steers.
///
/// A stand-in rather than the real coordinator, and it has to be: this package
/// may not depend on `routing_application`. What it can name is the port,
/// which is exactly the point — the screen works against a contract, and which
/// implementation ends up behind it is an app's decision. That the same
/// stand-in can play a heuristic and a solver is scenario 4 restated in a
/// test.
final class _Facade implements RoutingFacade {
  _Facade(this._plan);

  Result<RoutePlan, RoutingFailure> _plan;

  final StreamController<RoutePlan> _plans =
      StreamController<RoutePlan>.broadcast();

  /// The orders `resequence` was called with, in order.
  final List<List<String>> resequenced = [];

  /// The visited sets `recalculateOnDeviation` was called with, in order.
  final List<Set<StopId>> recalculatedWith = [];

  /// What `resequence` should answer, when it differs from the current plan.
  Result<RoutePlan, RoutingFailure>? resequenceAnswer;

  /// Replaces what the facade answers with from now on.
  ///
  /// A method rather than a setter, so that it reads as the test arranging a
  /// situation rather than as part of the port it is standing in for.
  // ignore: use_setters_to_change_properties
  void answersWith(Result<RoutePlan, RoutingFailure> plan) => _plan = plan;

  /// Pushes a plan to whoever is watching.
  void emit(RoutePlan plan) => _plans.add(plan);

  @override
  Future<Result<RoutePlan, RoutingFailure>> recalculateOnDeviation({
    required ActorId courier,
    required Set<StopId> visited,
  }) async {
    recalculatedWith.add(visited);
    return _plan;
  }

  @override
  Future<Result<RoutePlan, RoutingFailure>> resequence({
    required ActorId courier,
    required List<StopId> order,
  }) async {
    resequenced.add([for (final id in order) id.value]);
    return resequenceAnswer ?? _plan;
  }

  @override
  Stream<RoutePlan> changes() => _plans.stream;

  /// Every other method of the port, which this test does not use.
  ///
  /// A stub rather than overrides that return a plausible value. What it says
  /// is "this test is about the route screen"; a call to anything else throws,
  /// which is louder than a silent default.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  Future<void> close() => _plans.close();
}

T _unwrap<T, F>(Result<T, F> result) =>
    result.fold((value) => value, (failure) => throw StateError('$failure'));

/// Two stops a kilometre apart, both reachable well inside the afternoon.
final List<Stop> _stops = [
  RouteFixtures.stop('s1', east: 0.01),
  RouteFixtures.stop('s2', east: 0.02),
];

/// A stop whose window closed before the courier could possibly arrive.
Stop _closed(String id) => RouteFixtures.stop(
  id,
  east: 0.03,
  window: _unwrap(
    TravelWindow.between(
      opensAt: RouteFixtures.noon.subtract(const Duration(hours: 2)),
      closesAt: RouteFixtures.noon.subtract(const Duration(minutes: 1)),
    ),
  ),
);

RoutePlan _planFor(ActorId courier, List<Stop> stops, List<String> order) =>
    _unwrap(
      RoutePlan.of(
        id: _unwrap(RoutePlanId.parse('plan-other')),
        courier: courier,
        origin: RouteFixtures.depot,
        stops: stops,
        sequence: _unwrap(
          StopSequence.over(stops, [
            for (final id in order) RouteFixtures.stopId(id),
          ]),
        ),
        departAt: RouteFixtures.noon,
      ),
    );

void main() {
  late _Facade facade;
  late RouteController controller;

  setUp(() {
    facade = _Facade(Success(RouteFixtures.plan(_stops, ['s1', 's2'])));
    controller = RouteController(
      routing: facade,
      courier: RouteFixtures.courier(),
    );
  });

  tearDown(() async {
    controller.dispose();
    await facade.close();
  });

  group('RouteController', () {
    test('starts idle and asks for nothing', () {
      expect(controller.state, isA<RouteIdle>());
    });

    test('reads the route and reports what it found', () async {
      await controller.load();

      final state = controller.state;
      expect(state, isA<RouteReady>());
      expect((state as RouteReady).plan.sequence.length, 2);
    });

    test('no plan is unplanned, not failed', () async {
      // Where every day starts. Reporting it as an error would send a courier
      // looking for a problem that does not exist.
      facade.answersWith(const Failed(NoPlan('courier-1')));

      await controller.load();

      expect(controller.state, isA<RouteUnplanned>());
    });

    test('reports a route it could not read', () async {
      facade.answersWith(const Failed(RoutingUnavailable(detail: 'timeout')));

      await controller.load();

      expect(controller.state, isA<RouteFailed>());
    });

    test('an arrival moves the next stop without asking the facade', () async {
      await controller.load();
      expect((controller.state as RouteReady).nextStop!.value, 's1');

      controller.markArrived(RouteFixtures.stopId('s1'));

      expect((controller.state as RouteReady).nextStop!.value, 's2');
      expect(
        facade.recalculatedWith,
        hasLength(1),
        reason: 'nothing about the route changed, only which stop is next',
      );
    });

    test('the same arrival twice notifies once', () async {
      await controller.load();
      var notifications = 0;
      controller
        ..addListener(() => notifications++)
        ..markArrived(RouteFixtures.stopId('s1'))
        ..markArrived(RouteFixtures.stopId('s1'));

      expect(notifications, 1);
    });

    test('a state a widget is holding does not change under it', () async {
      // The visited set the controller keeps is mutable; the one it hands to
      // a state is a snapshot. Without the copy, marking a stop arrived would
      // silently change the state a widget had already been given.
      await controller.load();
      final before = controller.state as RouteReady;

      controller.markArrived(RouteFixtures.stopId('s1'));

      expect(before.visited, isEmpty);
      expect((controller.state as RouteReady).visited, hasLength(1));
    });

    test('redraws when this courier is replanned elsewhere', () async {
      controller.watch();

      facade.emit(_planFor(RouteFixtures.courier(), _stops, ['s2', 's1']));
      await Future<void>.delayed(Duration.zero);

      final state = controller.state as RouteReady;
      expect(state.plan.sequence.order.first.value, 's2');
    });

    test('ignores another courier on the same stream', () async {
      // A dispatcher container has one facade and many couriers' routes moving
      // through it. A screen that redrew on every plan would show one courier
      // the stops of whoever was replanned last.
      controller.watch();

      facade.emit(
        _planFor(RouteFixtures.courier('courier-2'), _stops, ['s2', 's1']),
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.state, isA<RouteIdle>());
    });

    test('watching twice keeps one subscription', () async {
      controller
        ..watch()
        ..watch();
      var notifications = 0;
      controller.addListener(() => notifications++);

      facade.emit(RouteFixtures.plan(_stops, ['s1', 's2']));
      await Future<void>.delayed(Duration.zero);

      expect(notifications, 1);
    });

    test('moving a stop up hands the domain the whole order', () async {
      await controller.load();

      await controller.moveUp(RouteFixtures.stopId('s2'));

      expect(facade.resequenced, [
        ['s2', 's1'],
      ]);
    });

    test('moving the first stop up asks for nothing', () async {
      await controller.load();

      await controller.moveUp(RouteFixtures.stopId('s1'));

      expect(facade.resequenced, isEmpty);
    });

    test('a refused reorder keeps the route and reports itself', () async {
      // The domain declined to change the plan, so the plan is still the
      // truth. Dropping to a failure state would blank a valid route because
      // somebody dragged a row somewhere it could not go.
      await controller.load();
      facade.resequenceAnswer = const Failed(
        SequenceDoesNotMatch(reason: 's3 is not on this route'),
      );

      await controller.reorder([RouteFixtures.stopId('s1')]);

      final state = controller.state as RouteReady;
      expect(state.plan.sequence.length, 2);
      expect(state.refusal, isA<SequenceDoesNotMatch>());
    });

    test('a refusal with nothing on screen is a failure', () async {
      facade.resequenceAnswer = const Failed(RoutingUnavailable());

      await controller.reorder([RouteFixtures.stopId('s1')]);

      expect(controller.state, isA<RouteFailed>());
    });
  });

  group('RouteScreen', () {
    testWidgets('shows the stops in driving order, with their times', (
      tester,
    ) async {
      await tester.pumpWidget(
        PeykTheme.wrap(
          child: RouteScreen(controller: controller),
        ),
      );
      await tester.pump();

      expect(find.text('Stop s1'), findsOneWidget);
      expect(find.text('Stop s2'), findsOneWidget);
      expect(find.text(RoutingStrings.next), findsOneWidget);
      // The finish time crosses as a UTC instant, not as "17:30". Turning it
      // into a courier's wall clock needs a timezone and a locale, and only
      // the app has both.
      expect(
        find.textContaining('${RoutingStrings.summary}(stops=2'),
        findsOneWidget,
      );
    });

    testWidgets('marks a stop that is already forecast late', (tester) async {
      // A plan may legitimately contain one: refusing to produce a route on a
      // morning that started badly is worse than a route that says which stop
      // is at risk.
      final stops = [..._stops, _closed('s3')];
      facade.answersWith(
        Success(RouteFixtures.plan(stops, ['s1', 's2', 's3'])),
      );

      await tester.pumpWidget(
        PeykTheme.wrap(
          child: RouteScreen(controller: controller),
        ),
      );
      await tester.pump();

      expect(find.text(RoutingStrings.late), findsOneWidget);
    });

    testWidgets('records an arrival and moves the marker', (tester) async {
      await tester.pumpWidget(
        PeykTheme.wrap(
          child: RouteScreen(controller: controller),
        ),
      );
      await tester.pump();

      await tester.tap(find.text(RoutingStrings.arrived).first);
      await tester.pump();

      expect(find.text(RoutingStrings.done), findsOneWidget);
    });

    testWidgets('offers no reordering unless the app allows it', (
      tester,
    ) async {
      // Defaults to false, so forgetting to think about it fails in the safe
      // direction: a courier cannot rewrite the afternoon a dispatcher planned.
      await tester.pumpWidget(
        PeykTheme.wrap(
          child: RouteScreen(controller: controller),
        ),
      );
      await tester.pump();

      expect(find.text(RoutingStrings.moveUp), findsNothing);
    });

    testWidgets('asks the facade to resequence when a row is moved up', (
      tester,
    ) async {
      await tester.pumpWidget(
        PeykTheme.wrap(
          child: RouteScreen(controller: controller, reorderable: true),
        ),
      );
      await tester.pump();

      await tester.tap(find.text(RoutingStrings.moveUp));
      await tester.pump();

      expect(facade.resequenced, [
        ['s2', 's1'],
      ]);
    });

    testWidgets('says nothing to drive on an empty route', (tester) async {
      // StopSequence.empty is explicitly not a failure: a courier who has not
      // been given work yet has an empty route.
      facade.answersWith(Success(RouteFixtures.plan(const [], const [])));

      await tester.pumpWidget(
        PeykTheme.wrap(
          child: RouteScreen(controller: controller),
        ),
      );
      await tester.pump();

      expect(find.text(RoutingStrings.nothingToDrive), findsOneWidget);
    });

    testWidgets('says nothing has been planned when nothing has', (
      tester,
    ) async {
      facade.answersWith(const Failed(NoPlan('courier-1')));

      await tester.pumpWidget(
        PeykTheme.wrap(
          child: RouteScreen(controller: controller),
        ),
      );
      await tester.pump();

      expect(
        find.text(RoutingStrings.unplanned),
        findsOneWidget,
      );
    });

    test('asks for a different key for every failure', () {
      // Seven cases, seven keys — the reason RoutingFailure is a sealed union
      // rather than a message. "The planner could not be reached" and "that
      // order does not describe this route" send a courier to different
      // places, and a screen that collapsed them into "something went wrong"
      // is what makes somebody restart an app that is working correctly.
      final keys = <RoutingFailure>[
        const NoPlan('courier-1'),
        const SequenceDoesNotMatch(reason: 'nothing visits s2'),
        const ConstraintUnsatisfiable(constraint: 'maxStops', reason: 'too'),
        const StopNotGeocoded(stopId: 's1', address: 'Bağdat Cd.'),
        const PositionUnavailable(),
        const RoutingUnavailable(),
        const MalformedRouteValue(field: 'stop.label', reason: 'is empty'),
      ].map(RouteScreen.describe).toList();

      expect(keys.toSet(), hasLength(7));
      expect(RoutingStrings.all, containsAll(keys));
    });

    // The two failures that leave a courier looking at something drivable.
    // Replacing the stops with an error page for either of them would stop
    // somebody driving a route that works — it is just not a fresh one.
    test('a stale route is an advisory, not a failure page', () {
      expect(RouteScreen.isAdvisory(const PositionUnavailable()), isTrue);
      expect(RouteScreen.isAdvisory(const RoutingUnavailable()), isTrue);
      expect(RouteScreen.isAdvisory(const NoPlan('courier-1')), isFalse);
    });
  });

  group('RoutingRoutes', () {
    test('guards somebody else s route behind a wider permission', () {
      // Two destinations, one screen. The difference between them is whose
      // route is on it, and that difference is a permission: declaring one
      // route with an optional segment would have made the guard the same for
      // both and handed every courier the whole operation.
      const module = RoutingRoutes();

      expect(module.moduleName, 'routing');
      expect(module.routes, hasLength(2));
      expect(
        module.routes.map((route) => route.requiredPermission).toSet(),
        hasLength(2),
      );
    });
  });
}
