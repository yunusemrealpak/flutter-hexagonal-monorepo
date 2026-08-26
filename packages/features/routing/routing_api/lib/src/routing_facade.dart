import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';

import 'geo_point.dart';
import 'route_constraint.dart';
import 'route_plan.dart';
import 'routing_failure.dart';
import 'stop.dart';
import 'stop_id.dart';

/// What the rest of the product asks routing to do.
///
/// Four intentions, and the fourth is the one that makes this feature more
/// than a sort: a route survives contact with a city, and something has to
/// decide when the plan stopped describing what the courier is doing.
abstract interface class RoutingFacade {
  /// Plans [courier]'s route from [origin] over [stops].
  ///
  /// The plan is produced, cached and returned. `departAt` is not a parameter:
  /// a use case takes it from the `Clock` port, so a caller cannot decide that
  /// a route starts at seven when it is nine.
  Future<Result<RoutePlan, RoutingFailure>> planRoute({
    required ActorId courier,
    required GeoPoint origin,
    required List<Stop> stops,
    List<RouteConstraint> constraints,
  });

  /// Reorders an existing plan by hand.
  ///
  /// This is a dispatcher's drag-and-drop. The order is checked against the
  /// plan's own stops and the estimates are recomputed, so a sequence that
  /// dropped a stop, repeated one or named a stranger is refused rather than
  /// stored.
  Future<Result<RoutePlan, RoutingFailure>> resequence({
    required ActorId courier,
    required List<StopId> order,
  });

  /// The stop [courier] should be heading for, given what they have done.
  ///
  /// `null` inside a success when the route is finished — an empty afternoon
  /// is not a failure.
  Future<Result<StopId?, RoutingFailure>> nextStop({
    required ActorId courier,
    required Set<StopId> visited,
  });

  /// Replans when the courier has left the route, and does nothing when they
  /// have not.
  ///
  /// Returns the plan either way, so a caller does not have to ask twice to
  /// find out what to draw. Whether it is a new plan is visible in its
  /// identifier, which is the reason plans are replaced rather than mutated.
  Future<Result<RoutePlan, RoutingFailure>> recalculateOnDeviation({
    required ActorId courier,
    required Set<StopId> visited,
  });

  /// Emits a plan whenever this courier's changes.
  Stream<RoutePlan> changes();
}
