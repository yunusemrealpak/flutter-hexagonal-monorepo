@Tags(['widget'])
library;

import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identity_api/identity_api.dart';
import 'package:routing_api/routing_api.dart';
import 'package:routing_presentation/routing_presentation.dart';
import 'package:routing_testing/routing_testing.dart';

/// The three routing ports, in one object this test steers.
///
/// A stand-in rather than the real coordinators, and it has to be: this
/// package may not depend on `routing_application`. What it can name is the
/// ports, which is exactly the point — the screen works against contracts, and
/// which implementation ends up behind them is an app's decision.
///
/// **One class implementing all three is a test's privilege, not a pattern.**
/// The workspace's apps build three separate coordinators precisely so that a
/// desk is never asked to construct the one holding `LocationStreamPort`; a
/// test that answers every port from memory has no such problem.
final class _Routing
    implements RoutePlanning, RouteSupervision, RouteFollowing {
  _Routing(this._plan);

  Result<RoutePlan, RoutingFailure> _plan;

  final StreamController<RoutePlan> _plans =
      StreamController<RoutePlan>.broadcast();

  /// The orders `resequence` was called with, in order.
  final List<List<String>> resequenced = [];

  /// The visited sets `recalculateOnDeviation` was called with, in order.
  final List<Set<StopId>> recalculatedWith = [];

  /// How many times `currentPlan` was asked.
  int currentPlanCalls = 0;

  /// What `resequence` should answer, when it differs from the current plan.
  Result<RoutePlan, RoutingFailure>? resequenceAnswer;

  /// The stops a resequenced plan is rebuilt over.
  List<Stop> stops = const [];

  /// Held open by a test that needs two calls to overlap.
  ///
  /// Every port here answers in the same microtask, so without it a handler
  /// finishes before the next event is delivered and no transformer has
  /// anything to decide — a concurrency test against an ungated fake passes
  /// whichever one is on the registration.
  Completer<void>? gate;

  Future<void> _held() async {
    if (gate case final gate?) {
      await gate.future;
    }
  }

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
    await _held();
    return _plan;
  }

  @override
  Future<Result<RoutePlan, RoutingFailure>> currentPlan({
    required ActorId courier,
  }) async {
    currentPlanCalls++;
    await _held();
    return _plan;
  }

  @override
  Future<Result<RoutePlan, RoutingFailure>> planRoute({
    required ActorId courier,
    required GeoPoint origin,
    required List<Stop> stops,
    List<RouteConstraint> constraints = const [],
  }) async => _plan;

  @override
  Future<Result<RoutePlan, RoutingFailure>> resequence({
    required ActorId courier,
    required List<StopId> order,
  }) async {
    resequenced.add([for (final id in order) id.value]);
    await _held();
    if (resequenceAnswer case final answer?) {
      return answer;
    }

    // The fake *applies* the order. A reorder computed against the plan the
    // previous one produced is otherwise indistinguishable from one computed
    // against the plan before it, which is the whole of what `sequential()`
    // buys here.
    return _plan = Success(
      _planFor(courier, stops, [
        for (final id in order) id.value,
      ]),
    );
  }

  @override
  Stream<RoutePlan> changes() => _plans.stream;

  /// Every other method of the ports, which this test does not use.
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
  late _Routing facade;
  late FollowedRouteBloc bloc;
  late SupervisedRouteBloc supervisor;

  setUp(() {
    facade = _Routing(Success(RouteFixtures.plan(_stops, ['s1', 's2'])))
      ..stops = _stops;
    bloc = FollowedRouteBloc(
      planning: facade,
      following: facade,
      courier: RouteFixtures.courier(),
    );
    supervisor = SupervisedRouteBloc(
      planning: facade,
      supervision: facade,
      courier: RouteFixtures.courier(),
    );
  });

  tearDown(() async {
    // Only a plain `test` may close a bloc itself. In a widget test the
    // provider owns it: `Bloc.close()` completes on microtasks scheduled
    // inside the fake-async zone, so awaiting it from a tear-down hangs with
    // no failure and no timeout — which is why the widget group below builds
    // its own bloc through `BlocProvider`.
    await bloc.close();
    await supervisor.close();
    await facade.close();
  });

  /// Reads the route, and waits for the port to answer.
  Future<void> load(RouteBloc bloc) async {
    bloc.add(const RouteRequested());
    await pumpEventQueue();
  }

  group('RouteBloc', () {
    test('starts idle and asks for nothing', () {
      expect(bloc.state, isA<RouteIdle>());
    });

    test('reads the route and reports what it found', () async {
      await load(bloc);

      final state = bloc.state;
      expect(state, isA<RouteReady>());
      expect((state as RouteReady).plan.sequence.length, 2);
    });

    test('no plan is unplanned, not failed', () async {
      // Where every day starts. Reporting it as an error would send a courier
      // looking for a problem that does not exist.
      facade.answersWith(const Failed(NoPlan('courier-1')));

      await load(bloc);

      expect(bloc.state, isA<RouteUnplanned>());
    });

    test('reports a route it could not read', () async {
      facade.answersWith(const Failed(RoutingUnavailable(detail: 'timeout')));

      await load(bloc);

      expect(bloc.state, isA<RouteFailed>());
    });

    test('a second read while one is out is dropped', () async {
      // On a courier's phone this read is `recalculateOnDeviation`, which may
      // *replace* the plan. Two of those in flight is two replans of one
      // afternoon, and a repeated tap on the retry button is the same request
      // twice — which is why the registration is `droppable()`.
      final gate = Completer<void>();
      facade.gate = gate;
      addTearDown(() => gate.isCompleted ? null : gate.complete());

      bloc
        ..add(const RouteRequested())
        ..add(const RouteRequested());
      await pumpEventQueue();
      gate.complete();
      await pumpEventQueue();

      expect(facade.recalculatedWith, hasLength(1));
    });

    test('an arrival moves the next stop without asking the facade', () async {
      await load(bloc);
      expect((bloc.state as RouteReady).nextStop!.value, 's1');

      bloc.add(StopArrived(RouteFixtures.stopId('s1')));
      await pumpEventQueue();

      expect((bloc.state as RouteReady).nextStop!.value, 's2');
      expect(
        facade.recalculatedWith,
        hasLength(1),
        reason: 'nothing about the route changed, only which stop is next',
      );
    });

    test('the same arrival twice emits once', () async {
      await load(bloc);
      final emitted = <RouteViewState>[];
      final states = bloc.stream.listen(emitted.add);
      addTearDown(states.cancel);

      bloc
        ..add(StopArrived(RouteFixtures.stopId('s1')))
        ..add(StopArrived(RouteFixtures.stopId('s1')));
      await pumpEventQueue();

      expect(emitted, hasLength(1));
    });

    test('a state a widget is holding does not change under it', () async {
      // The visited set the bloc keeps is mutable; the one it hands to a state
      // is a snapshot. Without the copy, marking a stop arrived would silently
      // change the state a widget had already been given.
      await load(bloc);
      final before = bloc.state as RouteReady;

      bloc.add(StopArrived(RouteFixtures.stopId('s1')));
      await pumpEventQueue();

      expect(before.visited, isEmpty);
      expect((bloc.state as RouteReady).visited, hasLength(1));
    });

    test('redraws when this courier is replanned elsewhere', () async {
      bloc.add(const RouteWatched());
      await pumpEventQueue();

      facade.emit(_planFor(RouteFixtures.courier(), _stops, ['s2', 's1']));
      await pumpEventQueue();

      final state = bloc.state as RouteReady;
      expect(state.plan.sequence.order.first.value, 's2');
    });

    test('ignores another courier on the same stream', () async {
      // A dispatcher container has one facade and many couriers' routes moving
      // through it. A screen that redrew on every plan would show one courier
      // the stops of whoever was replanned last.
      bloc.add(const RouteWatched());
      await pumpEventQueue();

      facade.emit(
        _planFor(RouteFixtures.courier('courier-2'), _stops, ['s2', 's1']),
      );
      await pumpEventQueue();

      expect(bloc.state, isA<RouteIdle>());
    });

    test('watching twice keeps one subscription', () async {
      // `restartable()` is what makes this true now: the second start cancels
      // the first rather than being ignored by a `??=`, so there is still one
      // subscription and one emission per plan.
      bloc
        ..add(const RouteWatched())
        ..add(const RouteWatched());
      await pumpEventQueue();
      final emitted = <RouteViewState>[];
      final states = bloc.stream.listen(emitted.add);
      addTearDown(states.cancel);

      facade.emit(RouteFixtures.plan(_stops, ['s1', 's2']));
      await pumpEventQueue();

      expect(emitted, hasLength(1));
    });

    test('opening a followed route checks for a deviation', () async {
      // A courier opening the screen is asking what to drive now, and the
      // honest answer to that includes noticing they have left the route.
      await load(bloc);

      expect(facade.recalculatedWith, hasLength(1));
      expect(facade.currentPlanCalls, 0);
    });
  });

  group('SupervisedRouteBloc', () {
    test('opening somebody else s route asks a question only', () async {
      // **The bug this split was opened to fix.** The read used to call
      // `recalculateOnDeviation` for every viewer, and that use case reads the
      // *calling device's* position — so a dispatcher opening a courier's
      // route compared the desk's coordinates against that courier's next stop
      // and could replan the afternoon from the office.
      await load(supervisor);

      expect(facade.currentPlanCalls, 1);
      expect(
        facade.recalculatedWith,
        isEmpty,
        reason: 'a desk has no position that answers a courier s question',
      );
    });

    test('moving a stop up hands the domain the whole order', () async {
      await load(supervisor);

      supervisor.add(StopMovedUp(RouteFixtures.stopId('s2')));
      await pumpEventQueue();

      expect(facade.resequenced, [
        ['s2', 's1'],
      ]);
    });

    test('moving the first stop up asks for nothing', () async {
      await load(supervisor);

      supervisor.add(StopMovedUp(RouteFixtures.stopId('s1')));
      await pumpEventQueue();

      expect(facade.resequenced, isEmpty);
    });

    test('a second move reads the order the first one produced', () async {
      // What `sequential()` buys, and why the order is computed inside the
      // handler rather than when the gesture happens. Both edits have to land,
      // in order, and the second is only meaningful against the plan the first
      // produced — computed against the plan before it, the second drag would
      // ask for an order that undoes the first.
      facade.stops = [..._stops, _closed('s3')];
      facade.answersWith(
        Success(RouteFixtures.plan(facade.stops, ['s1', 's2', 's3'])),
      );
      await load(supervisor);
      final gate = Completer<void>();
      facade.gate = gate;
      addTearDown(() => gate.isCompleted ? null : gate.complete());

      supervisor
        ..add(StopMovedUp(RouteFixtures.stopId('s3')))
        ..add(StopMovedUp(RouteFixtures.stopId('s3')));
      await pumpEventQueue();
      gate.complete();
      await pumpEventQueue();

      expect(facade.resequenced, [
        ['s1', 's3', 's2'],
        ['s3', 's1', 's2'],
      ]);
    });

    test('a refused reorder keeps the route and reports itself', () async {
      // The domain declined to change the plan, so the plan is still the
      // truth. Dropping to a failure state would blank a valid route because
      // somebody dragged a row somewhere it could not go.
      await load(supervisor);
      facade.resequenceAnswer = const Failed(
        SequenceDoesNotMatch(reason: 's3 is not on this route'),
      );

      supervisor.add(RouteResequenced([RouteFixtures.stopId('s1')]));
      await pumpEventQueue();

      final state = supervisor.state as RouteReady;
      expect(state.plan.sequence.length, 2);
      expect(state.refusal, isA<SequenceDoesNotMatch>());
    });

    test('a refusal with nothing on screen is a failure', () async {
      facade.resequenceAnswer = const Failed(RoutingUnavailable());

      supervisor.add(RouteResequenced([RouteFixtures.stopId('s1')]));
      await pumpEventQueue();

      expect(supervisor.state, isA<RouteFailed>());
    });
  });

  group('RouteScreen', () {
    /// The tree the screen needs, with the bloc **owned by the provider**.
    Widget screen({bool supervised = false}) => PeykTheme.wrap(
      child: BlocProvider<RouteBloc>(
        create: (_) => supervised
            ? SupervisedRouteBloc(
                planning: facade,
                supervision: facade,
                courier: RouteFixtures.courier(),
              )
            : FollowedRouteBloc(
                planning: facade,
                following: facade,
                courier: RouteFixtures.courier(),
              ),
        child: const RouteScreen(),
      ),
    );

    testWidgets('shows the stops in driving order, with their times', (
      tester,
    ) async {
      await tester.pumpWidget(screen());
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
      facade
        ..stops = stops
        ..answersWith(Success(RouteFixtures.plan(stops, ['s1', 's2', 's3'])));

      await tester.pumpWidget(screen());
      await tester.pump();

      expect(find.text(RoutingStrings.late), findsOneWidget);
    });

    testWidgets('records an arrival and moves the marker', (tester) async {
      await tester.pumpWidget(screen());
      await tester.pump();

      await tester.tap(find.text(RoutingStrings.arrived).first);
      await tester.pump();

      expect(find.text(RoutingStrings.done), findsOneWidget);
      expect(find.text(RoutingStrings.next), findsOneWidget);
    });

    testWidgets('an arrival redraws one stop and not the whole route', (
      tester,
    ) async {
      // What the per-stop selectors are for. An arrival emits a new
      // `RouteReady` over the *same* plan, so the list deliberately does not
      // rebuild; the marks that moved are selected per stop. The untouched
      // row is the same widget instance afterwards, which is what a rebuild
      // would change.
      await tester.pumpWidget(screen());
      await tester.pump();
      final rows = find.byType(PeykListRow);
      final before = tester.widget<PeykListRow>(rows.last);

      await tester.tap(find.text(RoutingStrings.arrived).first);
      await tester.pump();

      expect(find.text(RoutingStrings.done), findsOneWidget);
      expect(
        identical(before, tester.widget<PeykListRow>(rows.last)),
        isTrue,
      );
    });

    testWidgets('a replan redraws the whole list', (tester) async {
      // The other half of the same `buildWhen`. A plan is immutable, so a
      // different object is a different route — and comparing the case alone
      // would leave a courier looking at the order they were replanned out of.
      await tester.pumpWidget(screen());
      await tester.pump();

      facade.emit(_planFor(RouteFixtures.courier(), _stops, ['s2', 's1']));
      await tester.pump();

      final rows = tester
          .widgetList<PeykListRow>(find.byType(PeykListRow))
          .map((row) => row.title)
          .toList();
      expect(rows, ['Stop s2', 'Stop s1']);
    });

    testWidgets('a followed route offers no reordering', (tester) async {
      // Not a flag any more: a `FollowedRouteBloc` holds no
      // `RouteSupervision`, so there is nothing for the affordance to call and
      // the screen cannot draw it by mistake. A courier cannot rewrite the
      // afternoon a dispatcher planned.
      await tester.pumpWidget(screen());
      await tester.pump();

      expect(find.text(RoutingStrings.moveUp), findsNothing);
    });

    testWidgets('asks the facade to resequence when a row is moved up', (
      tester,
    ) async {
      await tester.pumpWidget(screen(supervised: true));
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

      await tester.pumpWidget(screen());
      await tester.pump();

      expect(find.text(RoutingStrings.nothingToDrive), findsOneWidget);
    });

    testWidgets('says nothing has been planned when nothing has', (
      tester,
    ) async {
      facade.answersWith(const Failed(NoPlan('courier-1')));

      await tester.pumpWidget(screen());
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
