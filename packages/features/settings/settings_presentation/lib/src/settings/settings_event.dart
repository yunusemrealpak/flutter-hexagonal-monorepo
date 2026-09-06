import 'package:settings_api/settings_api.dart';

/// What can happen to the settings screen.
sealed class SettingsEvent {
  const SettingsEvent();
}

/// Follow changes recorded anywhere in the app.
///
/// A second device, or another screen in this one, can change a preference.
/// Following the facade's stream is what keeps this screen from showing a
/// palette nobody has any more — and it is why the stream exists on the
/// contract rather than being a detail of the coordinator.
final class SettingsWatched extends SettingsEvent {
  /// Creates the event.
  const SettingsWatched();
}

/// Read the current preferences.
final class SettingsRequested extends SettingsEvent {
  /// Creates the event.
  const SettingsRequested();
}

/// A preference somebody chose.
///
/// **Sealed, and answered by one `on<PreferenceChosen>` under
/// `sequential()`.** Three kinds of change, one queue: they are different
/// things that all have to happen, and none may overtake another. A
/// transformer governs one registration, so three registrations would let a
/// palette write and a language write overlap — and the screen would re-enable
/// its rows when the first of them answered, while the second was still out.
sealed class PreferenceChosen extends SettingsEvent {
  const PreferenceChosen();
}

/// Record a new language.
final class LanguageChosen extends PreferenceChosen {
  /// Creates the event.
  const LanguageChosen(this.language);

  /// The language to record.
  final LanguageTag language;
}

/// Record a new palette.
final class ThemeChosen extends PreferenceChosen {
  /// Creates the event.
  const ThemeChosen(this.theme);

  /// The palette to record.
  final ThemePreference theme;
}

/// Record a new synchronisation policy.
final class SyncPolicyChosen extends PreferenceChosen {
  /// Creates the event.
  const SyncPolicyChosen(this.policy);

  /// The policy to record.
  final SyncPolicy policy;
}
