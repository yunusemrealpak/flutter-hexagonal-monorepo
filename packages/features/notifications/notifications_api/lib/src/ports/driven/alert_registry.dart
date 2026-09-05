import 'package:core_kernel/core_kernel.dart';

import '../../failures/notifications_failure.dart';

/// What this device remembers about having opened alerts.
///
/// A driven port, and it exists because the provider will not answer the
/// question. `PushMessagingClient` can subscribe a device to a topic and
/// unsubscribe it again, and there is no call anywhere in Firebase Messaging
/// that lists the topics a device is currently subscribed to. So the one fact
/// the product needs — *did this device open alerts for this person* — cannot
/// be recovered from the outside and has to be written down.
///
/// **It is not a preference.** A preference belongs to a person and follows
/// them onto a second handset; this belongs to the handset. A courier with a
/// work phone and a spare wants alerts on the one they are carrying, and
/// storing this in `settings`' `UserPreferences` would make both answer the
/// same way.
///
/// It speaks in `String` like every other driven port this feature has, so
/// that an adapter never has to see `identity_api` to write a row.
///
/// **What it remembers is intent, not capability.** The operating system can
/// contradict it at any moment — somebody turns notifications off in the
/// phone's own settings and nothing tells the application — which is why
/// `NotificationsFacade.alertStateFor` reconciles this against
/// `PermissionRequester.status` on every read rather than trusting it alone.
abstract interface class AlertRegistry {
  /// Whether this device opened alerts for [actorId].
  ///
  /// An actor nothing was ever recorded for is a successful read of `false`,
  /// not a failure. Only an unreachable or unreadable store fails.
  Future<Result<bool, NotificationsFailure>> isOpenFor(String actorId);

  /// Records that this device opened alerts for [actorId].
  ///
  /// Written only after the channel has actually opened. Recording an open
  /// that did not happen is how a switch ends up drawn on while the device
  /// receives nothing.
  Future<Result<void, NotificationsFailure>> rememberOpen(String actorId);

  /// Forgets that this device opened alerts for [actorId].
  ///
  /// Written only after the channel has actually closed. If unsubscribing
  /// failed the device is still receiving, and forgetting would record a state
  /// it does not have.
  Future<Result<void, NotificationsFailure>> forget(String actorId);
}
