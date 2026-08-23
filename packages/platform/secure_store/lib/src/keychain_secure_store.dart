import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'secure_store_failure_mapping.dart';

/// The [SecureStore] the shipped applications run on.
///
/// Refresh tokens and device-binding secrets, and nothing else. This is not a
/// safer [KeyValueStore]: platform-backed secure storage is slower, smaller,
/// and can refuse to answer while the device is locked. A user preference put
/// here buys nothing and costs a possible authentication prompt.
///
/// ## Options are the composition root's decision
///
/// [options] is the per-platform configuration the plugin expects —
/// `AndroidOptions(encryptedSharedPreferences: true).toMap()`,
/// `IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device)
/// .toMap()`, and so on. It is a constructor argument with no default on
/// purpose: accessibility class and backup behaviour are security decisions
/// that belong to the application, and a default here would be the kind that
/// nobody revisits.
///
/// ## Nothing here throws
///
/// Every method catches at the channel boundary and returns a `Result`, which
/// is invariant 1.2.9. The translation is in [secureStoreFailureFrom], and its
/// three cases exist because a caller behaves differently about each: retry,
/// ask the user, or treat the credential as gone.
final class KeychainSecureStore implements SecureStore {
  /// Stores through the given platform implementation, configured by
  /// [options].
  const KeychainSecureStore(this._platform, {required this.options});

  final FlutterSecureStoragePlatform _platform;

  /// The per-platform plugin configuration, as the plugin's option classes
  /// produce it.
  final Map<String, String> options;

  @override
  Future<Result<String?, SecureStoreFailure>> read(String key) async {
    try {
      // A missing key is a successful read of nothing, matching KeyValueStore.
      // Only an unreachable or unreadable store fails.
      return Success(await _platform.read(key: key, options: options));
    } on Object catch (error) {
      return Failed(secureStoreFailureFrom(error));
    }
  }

  @override
  Future<Result<void, SecureStoreFailure>> write(
    String key,
    String value,
  ) async {
    try {
      await _platform.write(key: key, value: value, options: options);
      return const Success(null);
    } on Object catch (error) {
      return Failed(secureStoreFailureFrom(error));
    }
  }

  @override
  Future<Result<void, SecureStoreFailure>> delete(String key) async {
    try {
      await _platform.delete(key: key, options: options);
      return const Success(null);
    } on Object catch (error) {
      return Failed(secureStoreFailureFrom(error));
    }
  }
}
