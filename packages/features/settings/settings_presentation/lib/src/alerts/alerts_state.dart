import 'package:notifications_api/notifications_api.dart';

/// What the alerts section of the settings screen can be showing.
///
/// Sealed and hand-written, like `SettingsState` beside it and for the same
/// reason: three small cases do not pay for a `build.yaml`.
///
/// **A refused change is a settled state carrying a failure, not a failed
/// one.** Somebody who taps the switch and is refused still has a device whose
/// alert state is known — it is closed — and the screen still has a switch to
/// draw. Modelling that as a failure would replace the control with an error
/// view and take away the thing they were trying to use.
sealed class AlertsState {
  /// Const so that a state can be built in a const context.
  const AlertsState();
}

/// The state is being read.
final class AlertsLoading extends AlertsState {
  /// Creates the state.
  const AlertsLoading();
}

/// The device has said where it stands.
final class AlertsSettled extends AlertsState {
  /// Creates the state over what the device reported.
  const AlertsSettled(this.alerts, {this.changing = false, this.failure});

  /// What the device reports.
  final AlertState alerts;

  /// Whether a change is in flight.
  ///
  /// The control is disabled rather than hidden while this is true, for the
  /// reason `_Choices` gives about the choices beside it: a row that vanished
  /// on every tap would flicker, and somebody would tap it twice.
  final bool changing;

  /// Why the last change did not take, when one did not.
  ///
  /// A `NotificationsFailure`, not a `String`. Turning it into a sentence
  /// happens at the widget, where the locale is known.
  final NotificationsFailure? failure;
}

/// Where the device stands could not be read at all.
///
/// Distinct from a settled state carrying a failure: there is no honest
/// position to draw a switch in, so the section offers a re-read instead of a
/// control.
final class AlertsUnreadable extends AlertsState {
  /// Creates the state.
  const AlertsUnreadable(this.failure);

  /// What went wrong, in notifications' own words.
  final NotificationsFailure failure;
}
