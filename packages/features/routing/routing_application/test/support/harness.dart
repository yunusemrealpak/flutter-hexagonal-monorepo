import 'package:core_kernel/core_kernel.dart';
import 'package:core_testing/core_testing.dart';
import 'package:routing_api/routing_api.dart';
import 'package:routing_application/routing_application.dart';
import 'package:routing_testing/routing_testing.dart';

/// Everything a routing use case needs, wired to fakes a test can steer.
///
/// The optimiser is `FakeRouteOptimizer`, which keeps the order it is given.
/// That is what makes an assertion in this package an assertion about *the use
/// case* — the order that comes back is the order that went in, so a test
/// about caching is not also a test about a heuristic. The heuristic's own
/// tests live next to the heuristic.
final class Harness {
  /// Builds the fakes and the use cases over them.
  Harness({double toleranceMetres = 750})
    : clock = FakeClock(RouteFixtures.noon),
      _tolerance = toleranceMetres;

  final double _tolerance;

  /// The optimiser under everything.
  final FakeRouteOptimizer optimizer = FakeRouteOptimizer();

  /// What the traffic service answers.
  final FakeTrafficData traffic = FakeTrafficData();

  /// Where plans are kept.
  final InMemoryRouteCache cache = InMemoryRouteCache();

  /// Where the courier is.
  final FakeLocationStream location = FakeLocationStream();

  /// Time, which only moves when a test moves it.
  final FakeClock clock;

  /// Identifiers, in a sequence a test can predict.
  final FakeIdGenerator ids = FakeIdGenerator('plan');

  /// What the use cases wrote down.
  final RecordingLogger logger = RecordingLogger();

  late final PlanRoute planRoute = PlanRoute(
    optimizer: optimizer,
    traffic: traffic,
    cache: cache,
    clock: clock,
    ids: ids,
    logger: logger,
  );

  late final Resequence resequence = Resequence(cache: cache);

  late final NextStop nextStop = NextStop(cache: cache);

  late final RecalculateOnDeviation recalculate = RecalculateOnDeviation(
    cache: cache,
    location: location,
    planRoute: planRoute,
    logger: logger,
    toleranceMetres: _tolerance,
  );

  late final RoutingCoordinator coordinator = RoutingCoordinator(
    planRoute: planRoute,
    resequence: resequence,
    nextStop: nextStop,
    recalculate: recalculate,
  );

  /// Plans a route over [stops] for the default courier.
  Future<Result<RoutePlan, RoutingFailure>> plan(
    List<Stop> stops, {
    List<RouteConstraint> constraints = const [],
  }) => planRoute((
    courier: RouteFixtures.courier(),
    origin: RouteFixtures.depot,
    stops: stops,
    constraints: constraints,
  ));

  /// Releases what the harness owns.
  Future<void> dispose() async {
    await coordinator.dispose();
    await location.dispose();
  }
}

/// Unwraps a [Result] where a failure means the test setup is wrong.
T unwrap<T, F>(Result<T, F> result) =>
    result.fold((value) => value, (failure) => throw StateError('$failure'));
