import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';

import 'alert_state.dart';
import 'inbox_entry.dart';
import 'notification_id.dart';
import 'notifications_failure.dart';

/// What the rest of the product may ask notifications to do.
///
/// A driving port. `notifications_core` implements it, presentation packages
/// and composition roots call it, and nothing on this surface says how an
/// alert reached the device or where it is kept.
///
/// It speaks in `ActorId` because every caller already holds a session — the
/// opposite choice from `InboxStore` and `AlertChannel`, which speak in
/// `String`. The pair is the rule in `docs/DEPENDENCY_RULES.md` §2.1 stated in
/// one file.
abstract interface class NotificationsFacade {
  /// Everything in [actor]'s inbox, newest first.
  Future<Result<List<InboxEntry>, NotificationsFailure>> inboxOf(ActorId actor);

  /// Marks one alert read.
  ///
  /// Answers with the entry as it now stands, so a caller does not have to
  /// re-read the inbox to redraw one row. Marking an alert that is already
  /// read succeeds and changes nothing — see `InboxEntry.readAtInstant`.
  Future<Result<InboxEntry, NotificationsFailure>> markRead(
    ActorId actor,
    NotificationId id,
  );

  /// Makes sure alerts for [actor] reach this device, asking for permission if
  /// that is what it takes.
  ///
  /// Called from a screen that has already explained why, never on first
  /// launch. `AlertsRefused` and `AlertsBlocked` are different answers on
  /// purpose: one of them can be asked again.
  Future<Result<void, NotificationsFailure>> openAlertsFor(ActorId actor);

  /// Stops alerts for [actor] reaching this device. Called on sign-out.
  Future<Result<void, NotificationsFailure>> closeAlertsFor(ActorId actor);

  /// Whether alerts for [actor] currently reach this device.
  ///
  /// Read before drawing any control that offers to change it, and read again
  /// after coming back from the system settings page — the operating system
  /// can revoke the permission at any time and tells the application nothing.
  ///
  /// A `Result` because the answer is partly a stored fact and a store can
  /// fail. Guessing on a failed read would draw a switch in a position nothing
  /// stands behind.
  Future<Result<AlertState, NotificationsFailure>> alertStateFor(ActorId actor);

  /// How many alerts are waiting to be seen, as it changes.
  ///
  /// A count rather than a list, because the badge that consumes it is drawn
  /// on every screen in the app and a list would make each new alert redraw
  /// all of them. The inbox screen reads [inboxOf] when somebody opens it.
  Stream<int> unreadCount();
}
