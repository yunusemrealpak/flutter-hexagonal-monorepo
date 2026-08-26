import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';
import 'package:routing_api/routing_api.dart';

import 'plan_route.dart';
import 'recalculate_on_deviation.dart';
import 'route_reads.dart';

/// The driving port's implementation: one intention per method, each of them a
/// call into a use case.
///
/// Deliberately thin, like every coordinator in this workspace. Everything
/// that decides anything is behind it — the estimates in `RoutePlan`, the
/// ordering in whichever `RouteOptimizerPort` an app bound, the deviation rule
/// in `RoutePlan.hasDeviated`. What this class adds is the shape of the port
/// and the change stream.
///
/// It is not called `RoutingFacadeImpl`. The name says what it does rather
/// than which interface it satisfies.
final class RoutingCoordinator implements RoutingFacade {
  /// Creates the coordinator over its use cases.
  RoutingCoordinator({
    required this._planRoute,
    required this._resequence,
    required this._nextStop,
    required this._recalculate,
  });

  final PlanRoute _planRoute;
  final Resequence _resequence;
  final NextStop _nextStop;
  final RecalculateOnDeviation _recalculate;

  final StreamController<RoutePlan> _changes =
      StreamController<RoutePlan>.broadcast();

  @override
  Future<Result<RoutePlan, RoutingFailure>> planRoute({
    required ActorId courier,
    required GeoPoint origin,
    required List<Stop> stops,
    List<RouteConstraint> constraints = const [],
  }) => _announce(
    _planRoute((
      courier: courier,
      origin: origin,
      stops: stops,
      constraints: constraints,
    )),
  );

  @override
  Future<Result<RoutePlan, RoutingFailure>> resequence({
    required ActorId courier,
    required List<StopId> order,
  }) => _announce(_resequence((courier: courier, order: order)));

  @override
  Future<Result<StopId?, RoutingFailure>> nextStop({
    required ActorId courier,
    required Set<StopId> visited,
  }) => _nextStop((courier: courier, visited: visited));

  @override
  Future<Result<RoutePlan, RoutingFailure>> recalculateOnDeviation({
    required ActorId courier,
    required Set<StopId> visited,
  }) => _announce(_recalculate((courier: courier, visited: visited)));

  /// Emits a plan whenever a courier's changes.
  ///
  /// A broadcast stream, so a stop list and a map can both listen. Nothing is
  /// emitted for a refused plan: the route did not change, and a screen that
  /// redrew on it would flicker for no reason.
  @override
  Stream<RoutePlan> changes() => _changes.stream;

  /// Releases the change stream.
  ///
  /// Called by the composition root when the container is torn down. The
  /// coordinator owns the controller, so it is the only thing that can.
  Future<void> dispose() => _changes.close();

  Future<Result<RoutePlan, RoutingFailure>> _announce(
    Future<Result<RoutePlan, RoutingFailure>> work,
  ) async {
    final result = await work;
    if (result case Success(value: final plan)) _changes.add(plan);
    return result;
  }
}
