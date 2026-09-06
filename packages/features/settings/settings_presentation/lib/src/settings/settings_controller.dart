import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:flutter/foundation.dart';
import 'package:identity_api/identity_api.dart';
import 'package:settings_api/settings_api.dart';

import 'settings_state.dart';

/// Drives the settings screen.
///
/// It holds one port — `SettingsFacade` — and no implementation. Whether the
/// preferences behind it are on the device or in a remote profile is decided
/// by whichever app composed it; this package cannot depend on
/// `settings_core` and does not want to.
///
/// A `ChangeNotifier` rather than a state-management library, for the reason
/// given in `sync_presentation`: no such library is a dependency of this
/// workspace, and introducing one in a light feature would make every feature
/// inherit the choice. The state type beside this class is the part that
/// matters.
final class SettingsController extends ChangeNotifier {
  /// Creates the controller for one actor.
  SettingsController({required this._settings, required this._actor});

  final SettingsFacade _settings;
  final ActorId _actor;

  StreamSubscription<UserPreferences>? _changes;

  SettingsState _state = const SettingsIdle();

  /// What the screen should be showing.
  SettingsState get state => _state;

  /// Starts following changes recorded anywhere in the app.
  ///
  /// A second device, or another screen in this one, can change a preference.
  /// Following the facade's stream is what keeps this screen from showing a
  /// palette nobody has any more — and it is why the stream exists on the
  /// contract rather than being a detail of the coordinator.
  void watch() {
    _changes ??= _settings.changes().listen(
      (preferences) => _emit(SettingsReady(preferences)),
    );
  }

  /// Reads the current preferences.
  Future<void> load() async {
    _emit(const SettingsLoading());
    _emit(_settled(await _settings.preferencesOf(_actor)));
  }

  /// Records a new language.
  Future<void> chooseLanguage(LanguageTag language) =>
      _save((actor) => _settings.chooseLanguage(actor, language));

  /// Records a new palette.
  Future<void> chooseTheme(ThemePreference theme) =>
      _save((actor) => _settings.chooseTheme(actor, theme));

  /// Records a new synchronisation policy.
  Future<void> chooseSyncPolicy(SyncPolicy policy) =>
      _save((actor) => _settings.chooseSyncPolicy(actor, policy));

  @override
  void dispose() {
    unawaited(_changes?.cancel());
    super.dispose();
  }

  /// Runs one change, keeping what is on screen visible while it is in flight.
  ///
  /// A change asked for from a state that has nothing to show — a failed load,
  /// say — is refused rather than sent. There is nothing to modify, and
  /// sending it anyway would write a set of preferences assembled from
  /// defaults over whatever is actually stored.
  Future<void> _save(
    Future<Result<UserPreferences, SettingsFailure>> Function(ActorId actor)
    change,
  ) async {
    final showing = switch (_state) {
      SettingsReady(:final preferences) => preferences,
      SettingsSaving(:final preferences) => preferences,
      SettingsIdle() || SettingsLoading() || SettingsFailed() => null,
    };
    if (showing == null) {
      return;
    }

    _emit(SettingsSaving(showing));
    _emit(_settled(await change(_actor)));
  }

  SettingsState _settled(Result<UserPreferences, SettingsFailure> result) =>
      switch (result) {
        Success(:final value) => SettingsReady(value),
        Failed(:final failure) => SettingsFailed(failure),
      };

  void _emit(SettingsState next) {
    _state = next;
    notifyListeners();
  }
}
