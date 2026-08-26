/// The routing UI: one courier's route, in the order it will be driven.
///
/// **This is where scenario 4 stops being about a port and starts being worth
/// something.** `RouteScreen` renders a `RoutePlan`, and nothing in this
/// package can discover which optimiser produced it. A courier in a tunnel is
/// looking at a nearest-neighbour ordering their own phone computed; a
/// dispatcher is looking at a solver's answer from a data centre. The two apps
/// bind different adapters and share every line of this package.
///
/// **Whose route it is arrives through the constructor.** Routing has one
/// presentation package, and the two apps use it for different subjects, so
/// reading the actor from `SessionReader` — the way
/// `shipments_presentation_courier` does — would be right in one app and wrong
/// in the other. `RouteController` takes an `ActorId`; the app decides where
/// it came from.
///
/// **What crosses, and what does not.** `ActorId` and the routing vocabulary,
/// and nothing else. This package never names a `Shipment`, and could not: a
/// `Stop` carries a `ShipmentId` as a field, so a screen that wanted to show
/// what is in the parcel would have to reach into `shipments_api` and would be
/// the second place in the product that knows what a shipment is.
///
/// This package holds no adapter and no use case. It depends on contracts
/// only, so what actually answers `RoutingFacade` is decided by whichever app
/// composed it: the real coordinator in `app_courier`, a fake in
/// `app_harness`.
library;

export 'src/route_controller.dart';
export 'src/route_screen.dart';
export 'src/route_view_state.dart';
export 'src/routing_routes.dart';
