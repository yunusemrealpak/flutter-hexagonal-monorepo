import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:identity_api/identity_api.dart';
import 'package:routing_api/routing_api.dart';

/// What a caller wants planned.
typedef PlanRequest = ({
  ActorId courier,
  GeoPoint origin,
  List<Stop> stops,
  List<RouteConstraint> constraints,
});

/// Produces a route for a courier and remembers it.
///
/// Six steps, and the order of the first two is the architectural point:
/// **the traffic profile is fetched here and handed to the optimiser**, rather
/// than being something an optimiser goes and gets. `RemoteSolverOptimizer`
/// could fetch it and `LocalHeuristicOptimizer` could not, and a port whose
/// two implementations see different inputs is a port whose contract cannot be
/// written down.
///
/// A traffic service that cannot be reached does not stop a plan. The route is
/// built against `TrafficProfile.assumed`, which produces a usable *ordering*
/// even when the times attached to it are guesses — and an ordering is what a
/// courier in a tunnel actually needs.
///
/// `maxDuration` is checked here rather than by the optimiser, and that is not
/// an oversight: the duration follows from the order, and the order is what an
/// optimiser is being asked for. Checking it before there is a plan would mean
/// checking it against a route nobody has chosen yet.
final class PlanRoute
    implements UseCase<PlanRequest, Result<RoutePlan, RoutingFailure>> {
  /// Creates the use case.
  const PlanRoute({
    required this._optimizer,
    required this._traffic,
    required this._cache,
    required this._clock,
    required this._ids,
    required this._logger,
  });

  final RouteOptimizerPort _optimizer;
  final TrafficDataPort _traffic;
  final RouteCache _cache;
  final Clock _clock;
  final IdGenerator _ids;
  final Logger _logger;

  @override
  Future<Result<RoutePlan, RoutingFailure>> call(PlanRequest request) async {
    final departAt = _clock.now();

    final traffic = (await _traffic.around(request.origin, at: departAt)).fold(
      (profile) => profile,
      (failure) {
        _logger.debug(
          'planning against assumed traffic',
          context: {'failure': '$failure'},
        );
        return TrafficProfile.assumed;
      },
    );

    final StopSequence sequence;
    switch (await _optimizer.optimise(
      OptimisationRequest(
        origin: request.origin,
        stops: request.stops,
        departAt: departAt,
        traffic: traffic,
        constraints: request.constraints,
      ),
    )) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        sequence = value;
    }

    final RoutePlanId id;
    switch (RoutePlanId.parse(_ids.newId())) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        id = value;
    }

    final built = RoutePlan.of(
      id: id,
      courier: request.courier,
      origin: request.origin,
      stops: request.stops,
      sequence: sequence,
      departAt: departAt,
      traffic: traffic,
    );
    final RoutePlan plan;
    switch (built.flatMap((p) => _checkDuration(p, request.constraints))) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        plan = value;
    }

    // The cache write is after the plan exists and its failure is swallowed on
    // purpose. A courier who has been given a route has been given a route; it
    // is not un-given because this device could not write it to disk. The cost
    // is a restart that has to ask again, which is much better than an error
    // where a stop list should be.
    final written = await _cache.write(plan);
    if (written case Failed(:final failure)) {
      _logger.warning(
        'route planned but not cached',
        context: {'courier': plan.courier.value, 'failure': '$failure'},
      );
    }

    return Success(plan);
  }

  Result<RoutePlan, RoutingFailure> _checkDuration(
    RoutePlan plan,
    List<RouteConstraint> constraints,
  ) {
    final limit = constraints.durationLimit;
    if (limit == null) return Success(plan);

    final takes = plan.finishesAt.difference(plan.departAt);
    if (takes <= limit) return Success(plan);

    return Failed(
      ConstraintUnsatisfiable(
        constraint: 'maxDuration',
        reason:
            'the best order found takes ${takes.inMinutes} minutes, '
            'longer than a limit of ${limit.inMinutes}',
      ),
    );
  }
}
