/// The routing contract: a courier's route, the order it is driven in, and
/// the times that follow from that order.
///
/// **The port this package exists to demonstrate is `RouteOptimizerPort`.**
/// Two implementations ship — a nearest-neighbour heuristic that runs on the
/// device and a remote solver that runs on a server — and both pass the same
/// contract kit. `app_courier` binds the first because a courier in a dead
/// zone still has to be given an order to drive; `app_dispatcher` binds the
/// second because an operator planning forty routes has a connection and needs
/// answers a phone cannot compute. Not one line of `routing_application`
/// changes between them.
///
/// What makes that contract writable is a split: **an optimiser returns a
/// permutation and nothing else.** The estimates are computed by `RoutePlan`,
/// from the order plus the traffic profile plus the service times. Comparing
/// orderings is exact; comparing instants would have two implementations
/// drifting apart on the first rounding difference — and it would let a solver
/// written by another team disagree about how this operation computes an
/// arrival time.
///
/// **The domain.** `Stop` is a place with a window and a service time;
/// `StopSequence` is an order that is checked against the stops it claims to
/// describe; `RoutePlan` is both plus the `Eta`s that follow. `GeoPoint`
/// carries the one piece of arithmetic — a haversine distance — that both
/// optimisers need and neither should own.
///
/// **The driving port.** `RoutingFacade`, implemented by
/// `routing_application`.
///
/// **The driven ports.** `RouteOptimizerPort`, `TrafficDataPort`,
/// `RouteCache`, `LocationStreamPort`, answered by `routing_infrastructure`.
library;

export 'src/eta.dart';
export 'src/geo_point.dart';
export 'src/location_stream_port.dart';
export 'src/optimisation_request.dart';
export 'src/route_cache.dart';
export 'src/route_constraint.dart';
export 'src/route_optimizer_port.dart';
export 'src/route_plan.dart';
export 'src/route_plan_id.dart';
export 'src/routing_facade.dart';
export 'src/routing_failure.dart';
export 'src/service_time.dart';
export 'src/stop.dart';
export 'src/stop_id.dart';
export 'src/stop_sequence.dart';
export 'src/traffic_data_port.dart';
export 'src/traffic_profile.dart';
export 'src/travel_window.dart';
