import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';

import '../../failures/settings_failure.dart';
import '../../values/language_tag.dart';
import '../../values/sync_policy.dart';
import '../../values/theme_preference.dart';
import '../../values/user_preferences.dart';

/// What the rest of the product may ask settings to do.
///
/// A driving port. `settings_core` implements it, presentation packages and
/// composition roots call it, and nothing on this surface says how a
/// preference is stored.
///
/// It speaks in `ActorId` — the identity, not the raw string — because every
/// caller already holds a session. That is the opposite choice from
/// `PreferencesStore` on purpose, and the pair is the clearest small statement
/// of the rule in `docs/DEPENDENCY_RULES.md` §2.1: an identity flows inwards
/// from a caller that has one, an identifier flows outwards to an adapter that
/// must not need one.
abstract interface class SettingsFacade {
  /// Reads what [actor] has chosen, falling back to the defaults.
  ///
  /// Never answers `null`. A person who has changed nothing has preferences —
  /// `UserPreferences.defaults()` — and making every caller re-decide what an
  /// absent record means is how three screens end up with three defaults.
  Future<Result<UserPreferences, SettingsFailure>> preferencesOf(ActorId actor);

  /// Changes the language [actor] wants to be spoken to in.
  Future<Result<UserPreferences, SettingsFailure>> chooseLanguage(
    ActorId actor,
    LanguageTag language,
  );

  /// Changes the palette [actor] wants.
  Future<Result<UserPreferences, SettingsFailure>> chooseTheme(
    ActorId actor,
    ThemePreference theme,
  );

  /// Changes when [actor]'s device may drain its outbox.
  Future<Result<UserPreferences, SettingsFailure>> chooseSyncPolicy(
    ActorId actor,
    SyncPolicy policy,
  );

  /// Every set of preferences this facade has settled on, as it settles on it.
  ///
  /// A broadcast stream, and it does not replay: a subscriber that needs the
  /// current value asks [preferencesOf] for it. Replaying the last value would
  /// make the stream a second source of truth for something the store already
  /// answers, and the two would drift the first time a write failed.
  Stream<UserPreferences> changes();
}
