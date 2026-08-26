/// The settings use cases and the adapter that answers them.
///
/// One package holding both halves of a hexagon, which is what the reduced
/// split means. The line between them is still there — it is
/// `PreferencesStore` in `settings_api` — but it is a line this package keeps
/// for itself rather than one the compiler draws:
///
/// - `LoadPreferences`, `ApplyPreferenceChange` and `SettingsCoordinator` are
///   the application half. They import `settings_api` and `core_ports` and
///   know nothing about JSON, keys or storage.
/// - `KeyValuePreferencesStore` and `PreferencesDto` are the infrastructure
///   half. They import no use case, and no use case imports them.
///
/// A composition root joins the two, exactly as it would if they lived in two
/// packages. That is the property that makes splitting this feature later a
/// move rather than a rewrite.
library;

export 'src/apply_preference_change.dart';
export 'src/key_value_preferences_store.dart';
export 'src/load_preferences.dart';
export 'src/preference_change.dart';
export 'src/preferences_dto.dart';
export 'src/resolve_language.dart';
export 'src/settings_coordinator.dart';
