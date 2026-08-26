import 'package:core_kernel/core_kernel.dart';
import 'package:core_testing/core_testing.dart';
import 'package:identity_api/identity_api.dart';
import 'package:settings_api/settings_api.dart';
import 'package:settings_core/settings_core.dart';

/// Everything a settings test needs, wired the way an app would wire it.
///
/// The harness exists so that the tests read as behaviour rather than as
/// assembly, and so that the assembly itself is exercised: every test below
/// runs against the real coordinator over the real use cases over the real
/// adapter, with only `KeyValueStore` faked. That is the seam the constitution
/// puts there, and faking anything nearer would test less of this package.
final class SettingsHarness {
  SettingsHarness() {
    final store = KeyValuePreferencesStore(store: keyValue);
    final load = LoadPreferences(store: store, logger: logger);
    facade = SettingsCoordinator(
      load: load,
      apply: ApplyPreferenceChange(load: load, store: store),
    );
  }

  /// The only fake in the suite.
  final InMemoryKeyValueStore keyValue = InMemoryKeyValueStore();

  /// Where the corrupt-record warning is looked for.
  final RecordingLogger logger = RecordingLogger();

  /// The facade under test.
  late final SettingsCoordinator facade;

  /// The actor every test acts as.
  static final ActorId courier =
      (ActorId.parse('courier-7') as Success<ActorId, IdentityFailure>).value;

  /// The key the adapter stores that actor's record under.
  static String get key => '${KeyValuePreferencesStore.keyPrefix}courier-7';

  /// Puts [raw] in the store as if a previous version of the product had
  /// written it.
  Future<void> preStore(String raw) async {
    await keyValue.write(key, raw);
  }

  /// The preferences behind a successful result.
  static UserPreferences valueOf(
    Result<UserPreferences, SettingsFailure> result,
  ) => (result as Success<UserPreferences, SettingsFailure>).value;

  /// The failure behind an unsuccessful one.
  static SettingsFailure failureOf(
    Result<UserPreferences, SettingsFailure> result,
  ) => (result as Failed<UserPreferences, SettingsFailure>).failure;
}
