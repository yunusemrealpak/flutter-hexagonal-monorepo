import 'package:core_ports/core_ports.dart';
import 'package:injectable/injectable.dart';
import 'package:routing_api/routing_api.dart';
import 'package:routing_application/routing_application.dart';
import 'package:routing_testing/routing_testing.dart';

/// routing, on fakes.
///
/// **Scenario 4 is the first registration in this file.** `RouteOptimizerPort`
/// has three implementations in the workspace — `LocalHeuristicOptimizer` on a
/// phone, `RemoteSolverOptimizer` in a data centre, `FakeRouteOptimizer` here
/// — and all three pass the same contract kit. `routing_application` is one
/// package in all three apps and does not change a line between them.
@module
abstract class HarnessRouting {
  /// The optimiser this app binds.
  @lazySingleton
  FakeRouteOptimizer get fakeOptimizer => FakeRouteOptimizer();

  /// The same instance, as the port.
  @lazySingleton
  RouteOptimizerPort optimizer(FakeRouteOptimizer fake) => fake;

  /// Traffic that never slows anybody down.
  @lazySingleton
  TrafficDataPort get traffic => FakeTrafficData();

  /// The last plan, in memory.
  @lazySingleton
  RouteCache get cache => InMemoryRouteCache();

  /// A position a test moves by hand rather than a device that moves itself.
  @lazySingleton
  FakeLocationStream get fakeLocation => FakeLocationStream();

  /// The same instance, as the port.
  @lazySingleton
  LocationStreamPort location(FakeLocationStream fake) => fake;

  /// Ordering a day's stops.
  @lazySingleton
  PlanRoute plan(
    RouteOptimizerPort optimizer,
    TrafficDataPort traffic,
    RouteCache cache,
    Clock clock,
    IdGenerator ids,
    Logger logger,
  ) => PlanRoute(
    optimizer: optimizer,
    traffic: traffic,
    cache: cache,
    clock: clock,
    ids: ids,
    logger: logger,
  );

  /// Changing the order by hand.
  @lazySingleton
  Resequence resequence(RouteCache cache) => Resequence(cache: cache);

  /// Where to go now.
  @lazySingleton
  NextStop nextStop(RouteCache cache) => NextStop(cache: cache);

  /// Replanning when the van goes somewhere else.
  @lazySingleton
  RecalculateOnDeviation recalculate(
    RouteCache cache,
    LocationStreamPort location,
    PlanRoute plan,
    Logger logger,
  ) => RecalculateOnDeviation(
    cache: cache,
    location: location,
    planRoute: plan,
    logger: logger,
  );

  /// The one implementation of `RoutingFacade`.
  @lazySingleton
  RoutingFacade routing(
    PlanRoute plan,
    Resequence resequence,
    NextStop nextStop,
    RecalculateOnDeviation recalculate,
  ) => RoutingCoordinator(
    planRoute: plan,
    resequence: resequence,
    nextStop: nextStop,
    recalculate: recalculate,
  );
}
