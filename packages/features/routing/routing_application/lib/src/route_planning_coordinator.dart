import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';
import 'package:routing_api/routing_api.dart';

import 'plan_route.dart';
import 'route_channel.dart';
import 'route_reads.dart';

/// `RoutePlanning`'s implementation: what both audiences do to a route.
///
/// Deliberately thin, like every coordinator in this workspace. Everything
/// that decides anything is behind it — the estimates in `RoutePlan`, the
/// ordering in whichever `RouteOptimizerPort` an app bound.
///
/// **Its collaborators are the point of the split.** A cache, an optimiser and
/// a traffic service, and not one of them asks where the caller is standing.
/// That is why a desk can compose this and could not compose
/// `RouteFollowingCoordinator`.
final class RoutePlanningCoordinator implements RoutePlanning {
  /// Creates the coordinator over its use cases.
  RoutePlanningCoordinator({
    required this._planRoute,
    required this._currentPlan,
    required this._channel,
  });

  final PlanRoute _planRoute;
  final CurrentPlan _currentPlan;
  final RouteChannel _channel;

  @override
  Future<Result<RoutePlan, RoutingFailure>> planRoute({
    required ActorId courier,
    required GeoPoint origin,
    required List<Stop> stops,
    List<RouteConstraint> constraints = const [],
  }) => _channel.announce(
    _planRoute((
      courier: courier,
      origin: origin,
      stops: stops,
      constraints: constraints,
    )),
  );

  @override
  Future<Result<RoutePlan, RoutingFailure>> currentPlan({
    required ActorId courier,
  }) => _currentPlan(courier);

  @override
  Stream<RoutePlan> changes() => _channel.plans;
}
