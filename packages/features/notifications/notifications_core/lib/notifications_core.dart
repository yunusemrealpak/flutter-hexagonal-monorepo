/// The notifications use cases and the adapters that answer them.
///
/// One package holding both halves of a hexagon. The line between them is
/// `InboxStore` and `AlertChannel` in `notifications_api`, and it is a line
/// this package keeps for itself rather than one the compiler draws:
///
/// - `ReadInbox`, `MarkAlertRead`, `RecordArrivingAlert`, `OpenAlerts`,
///   `CloseAlerts` and `NotificationsCoordinator` are the application half.
///   They import `notifications_api` and `core_ports`, and none of them can
///   name Firebase, a key or a JSON document.
/// - `PushAlertChannel`, `KeyValueInboxStore` and `InboxEntryDto` are the
///   infrastructure half. They import no use case, and no use case imports
///   them.
///
/// **`PushAlertChannel` is why this feature is worth reading.** It imports
/// `platform/push_messaging`, which a `feature_application` package may never
/// do — that row forbids `platform/*` outright, so a full-split feature has to
/// put this file in `_infrastructure`. A `feature_core` package may, and the
/// result is a package where a use case and the device adapter it will never
/// see are neighbours in the same `lib/src`.
library;

export 'src/close_alerts.dart';
export 'src/inbox_entry_dto.dart';
export 'src/key_value_alert_registry.dart';
export 'src/key_value_inbox_store.dart';
export 'src/mark_alert_read.dart';
export 'src/notifications_coordinator.dart';
export 'src/open_alerts.dart';
export 'src/push_alert_channel.dart';
export 'src/read_alert_state.dart';
export 'src/read_inbox.dart';
export 'src/record_arriving_alert.dart';
