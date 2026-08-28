import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';

import 'route_plan.dart';
import 'routing_failure.dart';
import 'stop_id.dart';

/// Overriding a route from outside the van.
///
/// A desk's half of routing. It is one operation, and it is separate for a
/// reason that costs nothing to state and a great deal to discover late:
/// reordering somebody else's afternoon is an authority a courier does not
/// hold, and a contract that offered it to both would be a contract neither
/// audience could be composed against honestly.
abstract interface class RouteSupervision {
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
}
