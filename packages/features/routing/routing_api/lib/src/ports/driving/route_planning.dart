import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';

import '../../entities/route_plan.dart';
import '../../entities/stop.dart';
import '../../failures/routing_failure.dart';
import '../../values/geo_point.dart';
import '../../values/route_constraint.dart';

/// Making a route exist, and reading the one that does.
///
/// The half of routing **both** audiences perform. A dispatcher plans a
/// courier's afternoon at the desk; a courier's own app plans one when nobody
/// planned it for them. Neither of them needs a device to do it, and that is
/// the test this interface is drawn to pass: every port behind these two
/// operations is a cache, an optimiser or a traffic service.
///
/// [currentPlan] is a query and nothing else. It exists because the screen
/// that opens on a route has to be able to *ask* what is planned without
/// causing a replan — see `RouteFollowing.recalculateOnDeviation` for the
/// operation it used to be answered by, and the reason that was wrong.
abstract interface class RoutePlanning {
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

  /// The plan [courier] is currently on, unchanged by the asking.
  ///
  /// `NoPlan` when nobody has planned one, which is where every day starts
  /// rather than a failure of this operation.
  Future<Result<RoutePlan, RoutingFailure>> currentPlan({
    required ActorId courier,
  });

  /// Emits a plan whenever this container's routes change.
  ///
  /// Every role that writes a plan announces it here, so a screen holding one
  /// role still sees a change another role made.
  Stream<RoutePlan> changes();
}
