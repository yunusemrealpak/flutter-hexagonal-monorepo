import 'package:core_kernel/core_kernel.dart';

/// Everything that can go wrong on the notifications ports.
///
/// Sealed, so a caller that handles the cases exhaustively keeps compiling
/// only for as long as it still handles all of them.
///
/// Four of the cases below describe *alerts* — whether this device can be
/// reached at all — and two describe the *inbox*. They are one hierarchy
/// because a caller usually holds both ports and wants one `switch`, and they
/// stay distinguishable because each case says which side it came from.
sealed class NotificationsFailure extends Failure {
  /// Const so that a failure can be built in a const context.
  const NotificationsFailure();
}

/// The inbox could not be read or written.
final class InboxUnavailable extends NotificationsFailure {
  /// Records that the inbox did not answer, with an optional [detail] for the
  /// log.
  const InboxUnavailable({this.detail});

  /// Adapter-supplied context. Never rendered to a user.
  final String? detail;

  @override
  String toString() => 'InboxUnavailable(${detail ?? 'no detail'})';
}

/// Nothing is in this inbox under the identifier that was asked for.
///
/// Its own case rather than a general failure because two devices reading the
/// same inbox will produce it routinely: one marks an alert read and clears
/// it, the other taps the row it still has on screen. The correct response is
/// to refresh, not to report a fault.
final class NotificationMissing extends NotificationsFailure {
  /// Records that [id] is not in the inbox.
  const NotificationMissing(this.id);

  /// The identifier that produced nothing.
  final String id;

  @override
  String toString() => 'NotificationMissing($id)';
}

/// The person has refused alerts, and can still be asked again.
final class AlertsRefused extends NotificationsFailure {
  /// Records that alerts were refused.
  const AlertsRefused();

  @override
  String toString() => 'AlertsRefused()';
}

/// Alerts are refused in a way the app cannot ask about again.
///
/// Separate from [AlertsRefused] because the two call for different screens:
/// one offers a button, the other has to send somebody to the system settings.
/// Collapsing them is how an app ends up with a button that does nothing.
final class AlertsBlocked extends NotificationsFailure {
  /// Records that alerts cannot be requested again from inside the app.
  const AlertsBlocked();

  @override
  String toString() => 'AlertsBlocked()';
}

/// This device could not be registered to receive alerts.
///
/// Worth retrying with backoff. A courier whose device never registered stops
/// receiving assignments, and nothing about the device looks wrong when it
/// happens.
final class AlertsUnreachable extends NotificationsFailure {
  /// Records that registration did not complete, with [detail] for the log.
  const AlertsUnreachable({required this.detail});

  /// What the adapter saw. Never rendered to a user.
  final String detail;

  @override
  String toString() => 'AlertsUnreachable($detail)';
}

/// A stored or incoming notification could not be read.
///
/// [field] names what was wrong and [reason] says why. Both are for a
/// developer; neither is a message to show anybody.
final class MalformedNotification extends NotificationsFailure {
  /// Records that [field] held a value described by [reason].
  const MalformedNotification({required this.field, required this.reason});

  /// Which part could not be read.
  final String field;

  /// Why it could not be read.
  final String reason;

  @override
  String toString() => 'MalformedNotification($field: $reason)';
}
