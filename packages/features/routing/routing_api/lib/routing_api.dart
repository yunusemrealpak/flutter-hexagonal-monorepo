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
/// **What crosses to another feature, and what does not.** This package names
/// `ActorId` and `ShipmentId`, and nothing else of theirs. Section 2.1 of
/// docs/DEPENDENCY_RULES.md states the rule the wider literature calls
/// *reference other contexts by identity*: an identifier crosses, a model does
/// not. `Stop` therefore holds routing's own `GeoPoint` and a plain label
/// rather than shipments' `AddressPoint` — see that type's own documentation
/// for what the borrowed model cost before it was removed.
///
/// `CourierReference` and `ShipmentReference` are the other half of it. They
/// read a foreign identifier and report a bad one as a *routing* failure, so
/// that `routing_infrastructure` — which may see no foreign feature at all —
/// can rebuild the identifiers this contract is expressed in without
/// depending on the packages that declare them.
///
/// **The driving ports, one per audience.** `RoutePlanning` is what both a
/// desk and a van perform; `RouteSupervision` is the desk's override;
/// `RouteFollowing` is what only the vehicle on the route can answer. They
/// were one `RoutingFacade` until phase 8, and splitting them is what lets
/// `app_dispatcher` compose routing without binding a GPS it would read the
/// wrong position from. The reasoning is in docs/ARCHITECTURE.md, scenario 5.
///
/// **The driven ports.** `RouteOptimizerPort`, `TrafficDataPort`,
/// `RouteCache`, `LocationStreamPort`, answered by `routing_infrastructure`.
library;

export 'src/courier_reference.dart';
export 'src/eta.dart';
export 'src/geo_point.dart';
export 'src/location_stream_port.dart';
export 'src/optimisation_request.dart';
export 'src/route_cache.dart';
export 'src/route_constraint.dart';
export 'src/route_following.dart';
export 'src/route_optimizer_port.dart';
export 'src/route_plan.dart';
export 'src/route_plan_id.dart';
export 'src/route_planning.dart';
export 'src/route_supervision.dart';
export 'src/routing_failure.dart';
export 'src/service_time.dart';
export 'src/shipment_reference.dart';
export 'src/stop.dart';
export 'src/stop_id.dart';
export 'src/stop_sequence.dart';
export 'src/traffic_data_port.dart';
export 'src/traffic_profile.dart';
export 'src/travel_window.dart';
