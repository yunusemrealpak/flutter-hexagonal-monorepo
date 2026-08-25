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

export 'src/address_point.dart';
export 'src/barcode.dart';
export 'src/barcode_resolver_port.dart';
export 'src/consignee.dart';
export 'src/courier_reference.dart';
export 'src/shipment.dart';
export 'src/shipment_cache.dart';
export 'src/shipment_delivered.dart';
export 'src/shipment_failed.dart';
export 'src/shipment_failure.dart';
export 'src/shipment_gateway.dart';
export 'src/shipment_id.dart';
export 'src/shipment_returned.dart';
export 'src/shipment_status.dart';
export 'src/shipment_summary.dart';
export 'src/shipments_facade.dart';
export 'src/status_transition.dart';
