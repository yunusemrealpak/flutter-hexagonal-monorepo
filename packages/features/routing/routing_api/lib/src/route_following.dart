import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';

import 'route_plan.dart';
import 'routing_failure.dart';
import 'stop_id.dart';

/// Driving the route, from the vehicle that is on it.
///
/// **Both operations are answers about where the caller physically is**, and
/// that is the whole reason this is its own interface. `LocationStreamPort`
/// reports *this device's* position; an app whose device is a desk cannot
/// answer it about a courier, so it must be able to compose routing without
/// being asked to.
///
/// The rule the workspace took from this: a driven port a device cannot
/// answer is declined honestly by an adapter — `DeskAlertChannel` does that.
/// A *driving* operation an audience never performs is not declined, it is
/// absent, because a refusal nobody can trigger is unreachable code standing
/// in for a compile-time fact.
abstract interface class RouteFollowing {
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
  ///
  /// A command, not a query: it may write a new plan and announce it. A screen
  /// that only wants to draw what is planned asks `RoutePlanning.currentPlan`.
  Future<Result<RoutePlan, RoutingFailure>> recalculateOnDeviation({
    required ActorId courier,
    required Set<StopId> visited,
  });
}
