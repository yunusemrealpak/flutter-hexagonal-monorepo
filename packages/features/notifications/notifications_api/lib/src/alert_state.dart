/// Whether alerts reach this device, as far as this application can tell.
///
/// Sealed, and three cases where the two things it is made of have eight
/// combinations. The reduction is deliberate: a screen has exactly two
/// decisions to make — whether to draw a switch, and which way it points — and
/// a state that carried "never asked" apart from "asked and refused" would
/// offer a distinction no caller can act on. The place that distinction still
/// matters is `PermissionRequester`, which keeps it because *asking* depends
/// on it.
///
/// **It is a device's answer, not a person's.** The same courier signed in on
/// two handsets gets two answers, because one of them may have notifications
/// turned off in its own settings. That is why the fact behind this lives in
/// `AlertRegistry` next to the device's storage rather than in a preference
/// that follows an identity around.
sealed class AlertState {
  /// Const so that a state can be built in a const context.
  const AlertState();
}

/// Alerts reach this device.
final class AlertsOpen extends AlertState {
  /// Records that alerts are open.
  const AlertsOpen();

  @override
  String toString() => 'AlertsOpen()';
}

/// Alerts do not reach this device, and the application may still ask.
///
/// Covers three situations that call for the same offer: nobody has been
/// asked, somebody was asked and said no, and somebody said yes and has not
/// turned alerts on here. All three are answered by the same switch in the
/// same position.
final class AlertsClosed extends AlertState {
  /// Records that alerts are closed.
  const AlertsClosed();

  @override
  String toString() => 'AlertsClosed()';
}

/// Alerts do not reach this device and the application may not ask again.
///
/// The only remaining route is the operating system's settings page, which is
/// what `PermissionRequester.openSettings` exists for. A screen that drew a
/// switch here would be offering a control that cannot work.
final class AlertsUnavailable extends AlertState {
  /// Records that alerts cannot be turned on from inside the application.
  const AlertsUnavailable();

  @override
  String toString() => 'AlertsUnavailable()';
}
