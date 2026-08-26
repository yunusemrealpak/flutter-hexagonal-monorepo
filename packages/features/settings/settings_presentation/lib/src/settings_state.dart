import 'package:settings_api/settings_api.dart';

/// What the settings screen can be showing.
///
/// Sealed and hand-written, in a package with no code generation at all. Four
/// small cases do not pay for a `build.yaml`.
///
/// [SettingsSaving] carries the preferences it is saving *over*, rather than
/// being a flag on [SettingsReady]. That is what lets the screen keep drawing
/// the choices somebody can see while a write is in flight, and it is why the
/// screen cannot accidentally render a half-applied change: the new value only
/// exists once the store has taken it.
sealed class SettingsState {
  const SettingsState();
}

/// Nothing has been asked for yet.
final class SettingsIdle extends SettingsState {
  /// Creates the state.
  const SettingsIdle();
}

/// The preferences are being read.
final class SettingsLoading extends SettingsState {
  /// Creates the state.
  const SettingsLoading();
}

/// The preferences arrived and nothing is in flight.
final class SettingsReady extends SettingsState {
  /// Creates the state.
  const SettingsReady(this.preferences);

  /// What is currently chosen.
  final UserPreferences preferences;
}

/// A change is being recorded.
final class SettingsSaving extends SettingsState {
  /// Creates the state over what is still on screen.
  const SettingsSaving(this.preferences);

  /// What was chosen before the change in flight.
  final UserPreferences preferences;
}

/// The preferences could not be read or a change could not be recorded.
final class SettingsFailed extends SettingsState {
  /// Creates the state.
  const SettingsFailed(this.failure);

  /// What went wrong, in settings' own words.
  ///
  /// A `SettingsFailure`, not a `String`. Turning it into a sentence happens
  /// at the widget, where the locale is known; a formatted message here would
  /// put English in a state object.
  final SettingsFailure failure;
}
