/// The routing use cases: pure Dart, and blind to which optimiser is behind
/// them.
///
/// That blindness is scenario 4 at the layer where it pays off. `PlanRoute`
/// holds a `RouteOptimizerPort` and never learns whether the ordering came
/// from a heuristic running on the phone or from a solver in a data centre —
/// so `app_courier` and `app_dispatcher` share every line of this package
/// while behaving completely differently in a tunnel.
///
/// Two decisions here are worth reading:
///
/// **`PlanRoute` fetches the traffic profile and hands it to the optimiser.**
/// A remote solver could fetch its own and a device-side heuristic could not,
/// and a port whose two implementations see different inputs is a port whose
/// contract cannot be written down. A traffic service that cannot be reached
/// does not stop a plan: the route is built against `TrafficProfile.assumed`,
/// which still produces a usable ordering.
///
/// **`RecalculateOnDeviation` does not replan when the position is unknown.**
/// A courier in a car park with no fix has not deviated — they are invisible,
/// and replanning on no evidence would reorder a route because somebody walked
/// into a basement.
///
/// `RoutingCoordinator` implements `RoutingFacade` by delegating to the four
/// use cases. It stays thin on purpose: if it ever grows a decision of its
/// own, that is the signal a use case is missing.
library;

export 'src/plan_route.dart';
export 'src/recalculate_on_deviation.dart';
export 'src/route_reads.dart';
export 'src/routing_coordinator.dart';
