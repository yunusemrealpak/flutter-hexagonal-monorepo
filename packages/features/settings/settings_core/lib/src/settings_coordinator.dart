import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';
import 'package:settings_api/settings_api.dart';

import 'apply_preference_change.dart';
import 'load_preferences.dart';
import 'preference_change.dart';

/// The one implementation of `SettingsFacade`.
///
/// It composes use cases and owns the change stream; it holds no rule of its
/// own. Every method here is a translation — an `ActorId` into the identifier
/// the store speaks, a named intention into a [PreferenceChange] — and the
/// moment one of them grows a branch, that branch belongs in a use case where
/// it can be tested without a facade.
///
/// This is the class that lets the reduced split stay honest. A caller holds
/// `SettingsFacade`; what it gets is this, and behind it are use cases that
/// have never heard of a key-value store. The adapter in the same package is
/// on the far side of `PreferencesStore` from all of it.
final class SettingsCoordinator implements SettingsFacade {
  /// Creates the coordinator over its use cases.
  SettingsCoordinator({required this._load, required this._apply});

  final LoadPreferences _load;
  final ApplyPreferenceChange _apply;

  final StreamController<UserPreferences> _changes =
      StreamController<UserPreferences>.broadcast();

  @override
  Future<Result<UserPreferences, SettingsFailure>> preferencesOf(
    ActorId actor,
  ) => _load(actor.value);

  @override
  Future<Result<UserPreferences, SettingsFailure>> chooseLanguage(
    ActorId actor,
    LanguageTag language,
  ) => _change(actor, ChooseLanguage(language));

  @override
  Future<Result<UserPreferences, SettingsFailure>> chooseTheme(
    ActorId actor,
    ThemePreference theme,
  ) => _change(actor, ChooseTheme(theme));

  @override
  Future<Result<UserPreferences, SettingsFailure>> chooseSyncPolicy(
    ActorId actor,
    SyncPolicy policy,
  ) => _change(actor, ChooseSyncPolicy(policy));

  @override
  Stream<UserPreferences> changes() => _changes.stream;

  /// Releases the change stream.
  ///
  /// A composition root owns this object for the life of the app and closes it
  /// on the way down. A broadcast controller with no subscribers is not a
  /// leak, but a stream nobody closed is one more thing a test has to
  /// remember, so the method exists and the tests call it.
  Future<void> dispose() => _changes.close();

  Future<Result<UserPreferences, SettingsFailure>> _change(
    ActorId actor,
    PreferenceChange change,
  ) async {
    final applied = await _apply(
      PreferenceChangeCommand(actorId: actor.value, change: change),
    );

    // Only a change that was actually recorded is announced. Emitting on the
    // way in would tell a screen that the palette had changed and leave the
    // store disagreeing the moment the write failed.
    if (applied case Success(:final value)) {
      _changes.add(value);
    }
    return applied;
  }
}
