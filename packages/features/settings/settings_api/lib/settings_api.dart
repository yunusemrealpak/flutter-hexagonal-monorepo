/// The settings contract: what a person may choose, and how it is stored.
///
/// A narrow surface, and deliberately so. Three preferences — language,
/// palette, synchronisation policy — one value that holds them, and two ports.
///
/// **The driving port** is `SettingsFacade`, implemented by `settings_core`
/// and called by presentation packages and composition roots. It speaks in
/// `ActorId`.
///
/// **The driven port** is `PreferencesStore`, answered by an adapter in
/// `settings_core`. It speaks in `String`. The pair is the smallest statement
/// of the rule that an identity flows inwards from a caller that has one and
/// an identifier flows outwards to an adapter that must not need one.
///
/// Nothing here is generated. Three enums, one value object and one immutable
/// record are less code than the `build.yaml` that would produce them, and a
/// package with no generated files is supposed to have no builder at all.
library;

export 'src/language_tag.dart';
export 'src/preferences_store.dart';
export 'src/settings_facade.dart';
export 'src/settings_failure.dart';
export 'src/sync_policy.dart';
export 'src/theme_preference.dart';
export 'src/user_preferences.dart';
