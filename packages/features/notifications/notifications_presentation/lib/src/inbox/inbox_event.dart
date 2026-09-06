import 'package:notifications_api/notifications_api.dart';

/// What can be asked of the inbox.
sealed class InboxEvent {
  const InboxEvent();
}

/// Read the inbox.
final class InboxRequested extends InboxEvent {
  /// Creates the event.
  const InboxRequested();
}

/// Mark one alert read.
final class AlertMarkedRead extends InboxEvent {
  /// Creates the event.
  const AlertMarkedRead(this.id);

  /// Which alert was opened.
  final NotificationId id;
}
