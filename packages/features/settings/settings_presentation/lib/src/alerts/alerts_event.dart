/// What can happen to the alerts section of the settings screen.
sealed class AlertsEvent {
  const AlertsEvent();
}

/// Read where the device stands.
///
/// Sent when the section is built, when the app comes back to the foreground,
/// and after a trip to the operating system's settings page — the three
/// moments the answer can have changed.
final class AlertsRequested extends AlertsEvent {
  /// Creates the event.
  const AlertsRequested();
}

/// Turn alerts on or off.
final class AlertsChosen extends AlertsEvent {
  /// Creates the event.
  const AlertsChosen({required this.on});

  /// Which way the switch was pushed.
  final bool on;
}

/// Send somebody to the operating system's settings page.
final class SystemSettingsOpened extends AlertsEvent {
  /// Creates the event.
  const SystemSettingsOpened();
}
