import 'package:core_kernel/core_kernel.dart';

import 'settings_failure.dart';
import 'user_preferences.dart';

/// Where a person's choices survive a restart.
///
/// A driven port: `settings_core` answers it, and an app's composition root
/// decides whether that answer is device storage, a remote profile service or
/// an in-memory map for a test.
///
/// **It takes a `String`, not an `ActorId`.** An identifier crossing a
/// boundary is a string on the wire either way, and a driven port whose
/// signature names another feature's type is a port its own adapter cannot
/// implement without depending on that feature. Reading it is the caller's
/// job, and the caller has already done it.
abstract interface class PreferencesStore {
  /// Reads what [actorId] has chosen, or `null` when they have chosen nothing.
  ///
  /// `null` is a successful read. Only an unreachable store, or a record that
  /// cannot be decoded, is a failure — see [PreferencesUnavailable] and
  /// [PreferencesCorrupted], which exist as separate cases because one of them
  /// can be recovered from by writing defaults and the other cannot.
  Future<Result<UserPreferences?, SettingsFailure>> read(String actorId);

  /// Stores [preferences] for [actorId], replacing whatever was there.
  Future<Result<void, SettingsFailure>> write(
    String actorId,
    UserPreferences preferences,
  );
}
