/// The shipments contract: a parcel, where it is, and what may happen to it
/// next.
///
/// The state machine is the point of this package, and it lives in `Shipment`
/// rather than in a use case:
///
/// ```text
/// awaitingAssignment -> assignedToCourier -> loadedOnVehicle
///   -> outForDelivery -> deliveredToConsignee | undeliverable
///                      | returnedToDepot
/// ```
///
/// A move that is not on that diagram returns
/// `ShipmentFailure.invalidTransition`, and it does so no matter which driving
/// adapter asked — a courier's scan screen, a dispatcher's table, a sync
/// drain, a test. That is what makes the rule a property of the domain instead
/// of a property of whoever remembered to check.
///
/// Three groups, as in every `_api` package: the domain, the driving port
/// (`ShipmentsFacade`), and the driven ports (`ShipmentGateway`,
/// `ShipmentCache`, `BarcodeResolverPort`). Plus the domain events shipments
/// publishes about itself, which is how `payments` learns that a delivery
/// completed without either feature depending on the other.
library;

export 'src/entities/shipment.dart';
export 'src/events/shipment_delivered.dart';
export 'src/events/shipment_failed.dart';
export 'src/events/shipment_returned.dart';
export 'src/failures/shipment_failure.dart';
export 'src/ports/driven/barcode_resolver_port.dart';
export 'src/ports/driven/shipment_cache.dart';
export 'src/ports/driven/shipment_gateway.dart';
export 'src/ports/driving/shipments_facade.dart';
export 'src/values/address_point.dart';
export 'src/values/barcode.dart';
export 'src/values/consignee.dart';
export 'src/values/courier_reference.dart';
export 'src/values/shipment_id.dart';
export 'src/values/shipment_status.dart';
export 'src/values/shipment_summary.dart';
export 'src/values/status_transition.dart';
