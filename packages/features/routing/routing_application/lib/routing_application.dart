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
/// **Three coordinators, one per driving port.** `RoutePlanningCoordinator`,
/// `RouteSupervisionCoordinator` and `RouteFollowingCoordinator` each take
/// only the use cases their own interface needs, and they share a
/// `RouteChannel` so that a plan written through one is seen by a screen
/// watching another. They were a single `RoutingCoordinator` until phase 8.
///
/// Splitting the *interfaces* was not enough on its own, and that is the
/// lesson worth carrying: `IdentityCoordinator` implements three ports from
/// one constructor, which segregates what a caller may ask but not what a
/// composition root must supply. An app that could not answer
/// `LocationStreamPort` needed the constructors split too.
///
/// They stay thin on purpose: if one ever grows a decision of its own, that is
/// the signal a use case is missing.
library;

export 'src/plan_route.dart';
export 'src/recalculate_on_deviation.dart';
export 'src/route_channel.dart';
export 'src/route_following_coordinator.dart';
export 'src/route_planning_coordinator.dart';
export 'src/route_reads.dart';
export 'src/route_supervision_coordinator.dart';
