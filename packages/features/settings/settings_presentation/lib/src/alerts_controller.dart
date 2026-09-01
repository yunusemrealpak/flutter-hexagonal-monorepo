import 'package:core_kernel/core_kernel.dart';
import 'package:flutter/foundation.dart';
import 'package:identity_api/identity_api.dart';
import 'package:notifications_api/notifications_api.dart';

import 'alerts_state.dart';

/// Drives the alerts section of the settings screen.
///
/// **It lives in `settings_presentation` and speaks to `notifications`**, and
/// both halves of that are the constitution rather than convenience. The
/// section is on the settings screen, so it belongs to the package that owns
/// that screen; the operation behind it is notifications', so it arrives
/// through `NotificationsFacade` — a foreign `_api`, which section 2 gives a
/// presentation package. A presentation package may not import another
/// presentation package, so the alternative was never "put it in
/// `notifications_presentation` and draw it here".
///
/// **Opening the system settings arrives as a function, not as a port.** The
/// capability belongs to `PermissionRequester` in `core_ports`, and section 2
/// does not give a presentation package that edge — deliberately, because a
/// screen that could read device permissions directly would stop asking the
/// feature that owns the decision. So the app supplies the action, exactly as
/// it supplies `onSignOut`, and this package still depends on nothing new.
///
/// **Every change is followed by a re-read.** The facade reconciles a stored
/// intent against an operating-system permission that can be revoked without
/// telling anybody, so what the device reports after a change is the only
/// answer worth drawing. Assuming the switch landed where it was pushed is how
/// a control ends up lying about the thing it controls.
final class AlertsController extends ChangeNotifier {
  /// Creates the controller for one actor.
  AlertsController({
    required this._notifications,
    required this._actor,
    required this._openSystemSettings,
  });

  final NotificationsFacade _notifications;
  final ActorId _actor;
  final Future<bool> Function() _openSystemSettings;

  AlertsState _state = const AlertsLoading();

  /// What the section should be showing.
  AlertsState get state => _state;

  /// Reads where the device stands.
  Future<void> load() async {
    final read = await _notifications.alertStateFor(_actor);
    _emit(
      switch (read) {
        Success(:final value) => AlertsSettled(value),
        Failed(:final failure) => AlertsUnreadable(failure),
      },
    );
  }

  /// Turns alerts on or off, then reads back what the device actually did.
  ///
  /// A change asked for from a state with nothing on screen is refused rather
  /// than sent, the same way `SettingsController._save` refuses one: there is
  /// no control to have been tapped.
  Future<void> choose({required bool on}) async {
    final showing = switch (_state) {
      AlertsSettled(:final alerts) => alerts,
      AlertsLoading() || AlertsUnreadable() => null,
    };
    if (showing == null) {
      return;
    }

    _emit(AlertsSettled(showing, changing: true));

    final changed = on
        ? await _notifications.openAlertsFor(_actor)
        : await _notifications.closeAlertsFor(_actor);

    final read = await _notifications.alertStateFor(_actor);
    _emit(
      switch (read) {
        Success(:final value) => AlertsSettled(
          value,
          failure: switch (changed) {
            Failed(:final failure) => failure,
            Success() => null,
          },
        ),
        // The change may well have worked; the device just will not say. There
        // is no position to draw a switch in either way.
        Failed(:final failure) => AlertsUnreadable(failure),
      },
    );
  }

  /// Sends somebody to the operating system's settings page, then reads back.
  ///
  /// The re-read is the point of doing it here rather than from the widget:
  /// coming back from that page is the one moment the answer can have changed
  /// without the application doing anything at all.
  Future<void> openSystemSettings() async {
    await _openSystemSettings();
    await load();
  }

  void _emit(AlertsState next) {
    _state = next;
    notifyListeners();
  }
}
