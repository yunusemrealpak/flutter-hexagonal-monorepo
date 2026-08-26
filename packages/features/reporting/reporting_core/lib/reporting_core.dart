/// The reporting use cases, the store behind the running totals, and the
/// watcher that builds them from what other features publish.
///
/// **This is a read model.** `shipments_application` publishes
/// `ShipmentDelivered`, `ShipmentFailed` and `ShipmentReturned` and has never
/// heard of reporting; this package subscribes and has never heard of
/// `shipments_application`. Both know only the `DomainEventBus` port and three
/// `DomainEvent` subtypes in an `_api` they already read.
///
/// It is a different use of the bus from `incidents`, and the difference is
/// worth naming. Incidents **reacts**: one event, one new thing in the world.
/// Reporting **accumulates**: every event moves a number, and those numbers
/// are the only thing this feature owns. That is why `ReportingFacade` is
/// read-only — there is no way to tell reporting that something happened
/// except by it happening.
///
/// **Nothing here asks what time it is.** Every instant arrives on an event,
/// and a day is attributed by domain time. A tally attributed by processing
/// time would move a delivery into today because a phone was switched on this
/// morning, and yesterday's total would change after somebody had read it.
///
/// The halves:
///
/// - `RecordOutcome`, `ReadRange`, `ShipmentOutcomeWatcher` and
///   `ReportingCoordinator` are the application half.
/// - `KeyValueTallyStore` and `TallyDto` are the infrastructure half. They
///   import no use case, and no use case imports them.
library;

export 'src/key_value_tally_store.dart';
export 'src/read_range.dart';
export 'src/record_outcome.dart';
export 'src/reporting_coordinator.dart';
export 'src/shipment_outcome_watcher.dart';
export 'src/tally_dto.dart';
