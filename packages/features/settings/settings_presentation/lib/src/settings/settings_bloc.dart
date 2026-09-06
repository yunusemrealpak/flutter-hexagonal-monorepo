import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core_kernel/core_kernel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:identity_api/identity_api.dart';
import 'package:settings_api/settings_api.dart';

import 'settings_event.dart';
import 'settings_state.dart';

/// Drives the settings screen.
///
/// It holds one port — `SettingsFacade` — and no implementation. Whether the
/// preferences behind it are on the device or in a remote profile is decided
/// by whichever app composed it; this package cannot depend on
/// `settings_core` and does not want to.
///
/// **The three writes share one `sequential()` registration.** Choosing a
/// language and then a palette are two different things somebody asked for and
/// both have to happen, in that order — so neither `droppable()`, which would
/// lose the second, nor `concurrent()`, which lets them overlap, is the right
/// policy. The overlap is what would be visible: [SettingsSaving] is what
/// disables the rows, and a write that answered while another was still out
/// would re-enable them mid-flight.
///
/// **Reading is `restartable()`**, because a newer read makes an older one
/// worthless — this is a query with no side effect, which is exactly the case
/// the transformer is for.
final class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  /// Creates the bloc for one actor.
  SettingsBloc({required this._settings, required this._actor})
    : super(const SettingsIdle()) {
    on<SettingsWatched>(_onWatched, transformer: restartable());
    on<SettingsRequested>(_onRequested, transformer: restartable());
    on<PreferenceChosen>(_onChosen, transformer: sequential());
  }

  final SettingsFacade _settings;
  final ActorId _actor;

  /// Holds the facade's stream for as long as the bloc is open.
  ///
  /// `emit.onEach` inside a `restartable()` handler, which replaced a nullable
  /// `StreamSubscription`, the `??=` that stopped a second `watch()` opening a
  /// second one, and a `dispose` override.
  Future<void> _onWatched(SettingsWatched event, Emitter<SettingsState> emit) =>
      emit.onEach<UserPreferences>(
        _settings.changes(),
        onData: (preferences) => emit(SettingsReady(preferences)),
      );

  Future<void> _onRequested(
    SettingsRequested event,
    Emitter<SettingsState> emit,
  ) async {
    emit(const SettingsLoading());
    emit(_settled(await _settings.preferencesOf(_actor)));
  }

  /// Runs one change, keeping what is on screen visible while it is in flight.
  ///
  /// A change asked for from a state that has nothing to show — a failed load,
  /// say — is refused rather than sent. There is nothing to modify, and
  /// sending it anyway would write a set of preferences assembled from
  /// defaults over whatever is actually stored.
  Future<void> _onChosen(
    PreferenceChosen event,
    Emitter<SettingsState> emit,
  ) async {
    final showing = switch (state) {
      SettingsReady(:final preferences) => preferences,
      SettingsSaving(:final preferences) => preferences,
      SettingsIdle() || SettingsLoading() || SettingsFailed() => null,
    };
    if (showing == null) {
      return;
    }

    emit(SettingsSaving(showing));
    emit(
      _settled(
        await switch (event) {
          LanguageChosen(:final language) => _settings.chooseLanguage(
            _actor,
            language,
          ),
          ThemeChosen(:final theme) => _settings.chooseTheme(_actor, theme),
          SyncPolicyChosen(:final policy) => _settings.chooseSyncPolicy(
            _actor,
            policy,
          ),
        },
      ),
    );
  }

  SettingsState _settled(Result<UserPreferences, SettingsFailure> result) =>
      switch (result) {
        Success(:final value) => SettingsReady(value),
        Failed(:final failure) => SettingsFailed(failure),
      };
}
