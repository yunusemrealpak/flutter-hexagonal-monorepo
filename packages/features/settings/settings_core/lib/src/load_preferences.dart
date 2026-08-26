import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:settings_api/settings_api.dart';

/// Reads what somebody has chosen, and decides what nothing means.
///
/// This is the one rule this feature has that is worth the name, and it is
/// three cases rather than one:
///
/// - **Nothing stored.** They have never changed a preference. The defaults
///   are the answer, and this is the ordinary path on a fresh install.
/// - **Something stored that cannot be read.** A record a previous version of
///   the product wrote and this one no longer understands. The defaults are
///   the answer again, and the event is logged, because losing three choices
///   quietly is better than a settings screen that refuses to open.
/// - **The store did not answer.** Nothing is known either way, and the
///   failure is passed on. Answering the defaults here would be the same
///   sentence as the case above and a different fact: the next write would put
///   the defaults over the top of choices that were never read.
///
/// The distinction is why `PreferencesCorrupted` and `PreferencesUnavailable`
/// are separate cases in `settings_api` rather than one failure with a
/// message.
final class LoadPreferences
    implements UseCase<String, Result<UserPreferences, SettingsFailure>> {
  /// Creates the use case.
  const LoadPreferences({required this._store, required this._logger});

  final PreferencesStore _store;
  final Logger _logger;

  @override
  Future<Result<UserPreferences, SettingsFailure>> call(String actorId) async {
    final stored = await _store.read(actorId);

    return switch (stored) {
      Success(value: final preferences?) => Success(preferences),
      Success() => const Success(UserPreferences.defaults()),
      Failed(failure: PreferencesCorrupted()) => _recover(actorId),
      Failed(:final failure) => Failed(failure),
    };
  }

  Result<UserPreferences, SettingsFailure> _recover(String actorId) {
    _logger.log(
      LogLevel.warning,
      'preferences for $actorId could not be read; falling back to defaults',
    );
    return const Success(UserPreferences.defaults());
  }
}
