import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:routing_api/routing_api.dart';

import 'plan_route.dart';
import 'route_reads.dart';

/// Replans when a courier has left the route, and does nothing when they have
/// not.
///
/// The use case that makes this feature more than a sort. A route survives
/// contact with a city for about twenty minutes, and something has to decide
/// when the plan has stopped describing what the courier is doing.
///
/// **It returns the plan either way.** A caller does not have to ask twice to
/// find out what to draw, and whether it is a *new* plan is visible in its
/// identifier — which is the reason plans are replaced rather than mutated.
///
/// Three things it deliberately does not do:
///
/// **It does not decide what a deviation is.** `RoutePlan.hasDeviated` does,
/// because both optimisers' plans have to be judged by the same rule.
///
/// **It does not replan when the position is unknown.** A courier in a car
/// park with no fix has not deviated; they are invisible. Replanning on no
/// evidence would reorder a route because somebody walked into a basement.
///
/// **It does not replan the whole day.** The stops already visited are gone,
/// and the new route starts from where the courier actually is — which is the
/// difference between a recalculation and a fresh morning.
final class RecalculateOnDeviation
    implements UseCase<ProgressRequest, Result<RoutePlan, RoutingFailure>> {
  /// Creates the use case.
  const RecalculateOnDeviation({
    required this._cache,
    required this._location,
    required this._planRoute,
    required this._logger,
    this.toleranceMetres = 750,
  });

  final RouteCache _cache;
  final LocationStreamPort _location;
  final PlanRoute _planRoute;
  final Logger _logger;

  /// How far off the direct line a courier may be before the route is redrawn.
  ///
  /// Seven hundred and fifty metres, and it is a *product* number rather than
  /// a measured one. It has to absorb the difference between a great-circle
  /// distance and a road — a city grid roughly doubles one into the other — so
  /// a tolerance much smaller reports a deviation on every normal journey, and
  /// one much larger lets a courier finish the wrong district before anybody
  /// notices.
  final double toleranceMetres;

  @override
  Future<Result<RoutePlan, RoutingFailure>> call(
    ProgressRequest request,
  ) async {
    final RoutePlan plan;
    switch (await _cache.read(request.courier.value)) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        plan = value;
    }

    final next = plan.nextStopAfter(request.visited);
    if (next == null) return Success(plan);

    final position = await _location.current();
    if (position case Failed(:final failure)) {
      _logger.debug(
        'not checking for a deviation without a position',
        context: {'courier': request.courier.value, 'failure': '$failure'},
      );
      return Success(plan);
    }

    final deviated = position.flatMap(
      (at) => plan.hasDeviated(
        position: at,
        nextStop: next,
        toleranceMetres: toleranceMetres,
      ),
    );
    switch (deviated) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(value: false):
        return Success(plan);
      case Success(value: true):
        break;
    }

    _logger.info(
      'replanning: the courier has left the route',
      context: {
        'courier': request.courier.value,
        'nextStop': next.value,
        'plan': plan.id.value,
      },
    );

    final remaining = [
      for (final stop in plan.stops)
        if (!request.visited.contains(stop.id)) stop,
    ];

    return _planRoute((
      courier: request.courier,
      origin: position.fold((at) => at, (_) => plan.origin),
      stops: remaining,
      constraints: const <RouteConstraint>[],
    ));
  }
}
