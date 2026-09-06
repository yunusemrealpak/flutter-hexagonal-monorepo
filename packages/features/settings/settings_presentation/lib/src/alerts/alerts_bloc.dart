import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core_kernel/core_kernel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:identity_api/identity_api.dart';
import 'package:notifications_api/notifications_api.dart';

import 'alerts_event.dart';
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
///
/// **Reading is `restartable()` and changing is `droppable()`.** The reads
/// arrive from three places — the section opening, the app resuming, a return
/// from the settings page — and when two of them overlap only the newer answer
/// is worth having. A change is the opposite: the section disables the switch
/// while one is in flight, so a second event during that window is the same
/// tap arriving twice, and answering it would ask the platform to subscribe a
/// device that is already subscribing.
final class AlertsBloc extends Bloc<AlertsEvent, AlertsState> {
  /// Creates the bloc for one actor.
  AlertsBloc({
    required this._notifications,
    required this._actor,
    required this._openSystemSettings,
  }) : super(const AlertsLoading()) {
    on<AlertsRequested>(_onRequested, transformer: restartable());
    on<AlertsChosen>(_onChosen, transformer: droppable());
    on<SystemSettingsOpened>(_onSystemSettingsOpened, transformer: droppable());
  }

  final NotificationsFacade _notifications;
  final ActorId _actor;
  final Future<bool> Function() _openSystemSettings;

  Future<void> _onRequested(
    AlertsRequested event,
    Emitter<AlertsState> emit,
  ) async {
    emit(_read(await _notifications.alertStateFor(_actor)));
  }

  /// Turns alerts on or off, then reads back what the device actually did.
  ///
  /// A change asked for from a state with nothing on screen is refused rather
  /// than sent, the same way `SettingsBloc` refuses one: there is no control
  /// to have been tapped.
  ///
  /// The re-read happens here rather than by adding [AlertsRequested], because
  /// the answer has to be drawn *with* the refusal the change came back with,
  /// and a second event could not carry it.
  Future<void> _onChosen(AlertsChosen event, Emitter<AlertsState> emit) async {
    final showing = switch (state) {
      AlertsSettled(:final alerts) => alerts,
      AlertsLoading() || AlertsUnreadable() => null,
    };
    if (showing == null) {
      return;
    }

    emit(AlertsSettled(showing, changing: true));

    final changed = event.on
        ? await _notifications.openAlertsFor(_actor)
        : await _notifications.closeAlertsFor(_actor);

    final read = await _notifications.alertStateFor(_actor);
    emit(
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
  /// The read is re-dispatched rather than done here, so every read of the
  /// device's answer goes through one handler under one policy. Coming back
  /// from that page is the one moment the answer can have changed without the
  /// application doing anything at all — and it is also a moment the app's
  /// own resume listener asks about, which is exactly the overlap
  /// `restartable()` is there to collapse.
  Future<void> _onSystemSettingsOpened(
    SystemSettingsOpened event,
    Emitter<AlertsState> emit,
  ) async {
    await _openSystemSettings();
    add(const AlertsRequested());
  }

  AlertsState _read(Result<AlertState, NotificationsFailure> state) =>
      switch (state) {
        Success(:final value) => AlertsSettled(value),
        Failed(:final failure) => AlertsUnreadable(failure),
      };
}
