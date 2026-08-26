import 'package:core_kernel/core_kernel.dart';
import 'package:settings_api/settings_api.dart';

import 'load_preferences.dart';
import 'preference_change.dart';

/// What a person is asking for, and who is asking.
///
/// A command object rather than two positional parameters, because
/// `UseCase.call` takes one input and because a record of two strings at the
/// call site is one transposition away from writing another actor's
/// preferences.
final class PreferenceChangeCommand {
  /// Creates the command.
  const PreferenceChangeCommand({
    required this.actorId,
    required this.change,
  });

  /// Whose preferences are being changed, as the store spells it.
  final String actorId;

  /// What is being changed.
  final PreferenceChange change;
}

/// Records one preference change, and answers with the whole set.
///
/// Read, modify, write — in that order and in one place. The read goes through
/// [LoadPreferences] rather than the store directly, which is what makes a
/// corrupt record recoverable: the load answers with the defaults, this use
/// case applies the change to them, and the write replaces the record nobody
/// could read.
///
/// It answers with the full [UserPreferences] rather than with nothing,
/// because every caller wants them: the screen that made the change has to
/// redraw, and returning `void` would send it straight back to ask for what
/// this use case already had in hand.
final class ApplyPreferenceChange
    implements
        UseCase<
          PreferenceChangeCommand,
          Result<UserPreferences, SettingsFailure>
        > {
  /// Creates the use case.
  const ApplyPreferenceChange({required this._load, required this._store});

  final LoadPreferences _load;
  final PreferencesStore _store;

  @override
  Future<Result<UserPreferences, SettingsFailure>> call(
    PreferenceChangeCommand command,
  ) async {
    final current = await _load(command.actorId);
    if (current case Failed(:final failure)) {
      return Failed(failure);
    }

    final next = command.change.applyTo(
      (current as Success<UserPreferences, SettingsFailure>).value,
    );

    // A write that changes nothing is still a write, and that is on purpose:
    // choosing the palette you already had should not be the one action in the
    // product that silently does nothing when the disk is full.
    final written = await _store.write(command.actorId, next);

    return switch (written) {
      Failed(:final failure) => Failed(failure),
      Success() => Success(next),
    };
  }
}
