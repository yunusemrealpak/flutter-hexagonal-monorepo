/// The incidents use cases, the log that answers them, and the watcher that
/// opens an incident when a shipment reports that it failed.
///
/// One package holding both halves of a hexagon:
///
/// - `ReportIncident`, `ListOpenIncidents`, `EscalateOverdue`,
///   `ResolveIncident`, `ShipmentFailureWatcher` and `IncidentsCoordinator`
///   are the application half.
/// - `KeyValueIncidentLog` and `IncidentDto` are the infrastructure half. They
///   import no use case, and no use case imports them.
///
/// **`ShipmentFailureWatcher` is scenario 2 in a light feature.**
/// `shipments_application` publishes `ShipmentFailed` and has never heard of
/// incidents; this package subscribes and has never heard of
/// `shipments_application`. Both know only the `DomainEventBus` port and a
/// `DomainEvent` subtype in an `_api` package they both already read.
///
/// **`ReasonClassifier` is why the event carries a `String`.** The taxonomy of
/// why a delivery failed belongs to `delivery`, which owns
/// `NonDeliveryReason`; putting an enum on the event would have made a second
/// copy of it, quietly diverging. What crosses the bus is an identifier and a
/// phrase, and the guess this package makes from that phrase is honest about
/// being a guess: anything it cannot place is `unclassified` rather than the
/// nearest plausible category.
library;

export 'src/escalate_overdue.dart';
export 'src/incident_dto.dart';
export 'src/incidents_coordinator.dart';
export 'src/key_value_incident_log.dart';
export 'src/list_open_incidents.dart';
export 'src/reason_classifier.dart';
export 'src/report_incident.dart';
export 'src/resolve_incident.dart';
export 'src/shipment_failure_watcher.dart';
