/// The notifications contract: what lands in a courier's inbox, and how it
/// gets there.
///
/// **The domain.** `InboxEntry`, `NotificationId`, `NotificationKind` — an
/// alert that carries a localisation key and its arguments rather than a
/// sentence, and a read mark that is an instant rather than a boolean.
///
/// **The driving port** is `NotificationsFacade`, implemented by
/// `notifications_core`. It speaks in `ActorId`.
///
/// **The driven ports** are `InboxStore` and `AlertChannel`, answered by
/// adapters in `notifications_core`. They speak in `String`.
///
/// `AlertChannel` is the one worth reading twice. It is the product's words —
/// can this person be reached, and what has reached them — and it is answered
/// using `PushMessagingClient` from `platform/push_messaging`, which is
/// Firebase's words. Two interfaces that look almost the same, on the two
/// sides of the line `docs/DEPENDENCY_RULES.md` §2.2 draws.
library;

export 'src/alert_channel.dart';
export 'src/arriving_alert.dart';
export 'src/inbox_entry.dart';
export 'src/inbox_store.dart';
export 'src/notification_id.dart';
export 'src/notification_kind.dart';
export 'src/notifications_facade.dart';
export 'src/notifications_failure.dart';
