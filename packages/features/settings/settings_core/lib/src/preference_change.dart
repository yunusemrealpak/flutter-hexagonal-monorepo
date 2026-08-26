import 'package:settings_api/settings_api.dart';

/// One thing a person can change about how the product behaves.
///
/// Sealed and declared here rather than in `settings_api`, because it is not
/// part of the contract: `SettingsFacade` offers three named methods, and this
/// type exists so that the read-modify-write behind all three is written once.
/// Putting it in the contract would publish an indirection nobody outside this
/// package needs.
sealed class PreferenceChange {
  const PreferenceChange();

  /// Applies this change to [preferences].
  ///
  /// Behaviour on the change rather than a `switch` in the use case. A fourth
  /// preference then arrives as one new case that the compiler makes
  /// exhaustive, instead of as a branch somebody has to remember to add.
  UserPreferences applyTo(UserPreferences preferences);
}

/// Speak to them in another language.
final class ChooseLanguage extends PreferenceChange {
  /// Creates the change.
  const ChooseLanguage(this.language);

  /// The language they asked for.
  final LanguageTag language;

  @override
  UserPreferences applyTo(UserPreferences preferences) =>
      preferences.copyWith(language: language);
}

/// Use another palette.
final class ChooseTheme extends PreferenceChange {
  /// Creates the change.
  const ChooseTheme(this.theme);

  /// The palette they asked for.
  final ThemePreference theme;

  @override
  UserPreferences applyTo(UserPreferences preferences) =>
      preferences.copyWith(theme: theme);
}

/// Drain the outbox on other terms.
final class ChooseSyncPolicy extends PreferenceChange {
  /// Creates the change.
  const ChooseSyncPolicy(this.policy);

  /// The policy they asked for.
  final SyncPolicy policy;

  @override
  UserPreferences applyTo(UserPreferences preferences) =>
      preferences.copyWith(syncPolicy: policy);
}
