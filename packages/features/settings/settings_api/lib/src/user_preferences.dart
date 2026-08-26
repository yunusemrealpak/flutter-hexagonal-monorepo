import 'package:meta/meta.dart';

import 'language_tag.dart';
import 'sync_policy.dart';
import 'theme_preference.dart';

/// Everything this product lets a person decide about how it behaves.
///
/// **Not an `Entity`, and the omission is the design.** Preferences have no
/// identity of their own: two couriers who both want Turkish, a dark palette
/// and unmetered-only synchronisation hold the same preferences, and there is
/// no sense in which one of them is "a different preferences". The actor is
/// the *key the record is stored under*, not a field of the record — which is
/// why `PreferencesStore` takes an actor identifier and this type does not
/// carry one.
///
/// That distinction is what keeps this feature's driven port free of
/// `identity_api`. The driving port `SettingsFacade` speaks in `ActorId`
/// because a caller has an identity in hand; the store speaks in `String`
/// because an adapter should not have to see another feature to write a row.
@immutable
final class UserPreferences {
  /// Creates a set of preferences.
  const UserPreferences({
    required this.language,
    required this.theme,
    required this.syncPolicy,
  });

  /// What somebody gets before they have chosen anything.
  ///
  /// Const, and every field of it is a value the type itself declares, so the
  /// defaults are available on the path where a `Result` cannot be unwrapped:
  /// a store that answers "nothing stored" has to produce these without
  /// parsing.
  const UserPreferences.defaults()
    : language = LanguageTag.turkish,
      theme = ThemePreference.system,
      syncPolicy = SyncPolicy.unmeteredOnly;

  /// The language to speak.
  final LanguageTag language;

  /// The palette to use.
  final ThemePreference theme;

  /// When this device may drain its outbox.
  final SyncPolicy syncPolicy;

  /// Returns a copy with the given fields replaced.
  ///
  /// The type is immutable, so changing one preference produces a new value
  /// rather than mutating a shared one. A screen holding the old value keeps
  /// rendering the old value until it is handed the new one, which is what
  /// makes a stale frame impossible to produce accidentally.
  UserPreferences copyWith({
    LanguageTag? language,
    ThemePreference? theme,
    SyncPolicy? syncPolicy,
  }) => UserPreferences(
    language: language ?? this.language,
    theme: theme ?? this.theme,
    syncPolicy: syncPolicy ?? this.syncPolicy,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserPreferences &&
          other.language == language &&
          other.theme == theme &&
          other.syncPolicy == syncPolicy;

  @override
  int get hashCode => Object.hash(language, theme, syncPolicy);

  @override
  String toString() =>
      'UserPreferences(${language.value}, ${theme.name}, ${syncPolicy.name})';
}
