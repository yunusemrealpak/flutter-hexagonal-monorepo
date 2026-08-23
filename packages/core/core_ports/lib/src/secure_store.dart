import 'package:core_kernel/core_kernel.dart';
import 'key_value_store.dart';
import 'secure_store_failure.dart';

/// Reads and writes values that must not be recoverable from a device backup
/// or a filesystem dump.
///
/// For refresh tokens, device binding secrets and nothing else. It is not a
/// faster or safer [KeyValueStore]: platform-backed secure storage is slower,
/// smaller, and can refuse to answer while the device is locked. Putting a
/// user preference here buys nothing and costs a possible authentication
/// prompt.
abstract interface class SecureStore {
  /// Reads the secret at [key], or `null` when nothing is stored there.
  Future<Result<String?, SecureStoreFailure>> read(String key);

  /// Stores [value] at [key], replacing whatever was there.
  Future<Result<void, SecureStoreFailure>> write(String key, String value);

  /// Removes [key]. Removing a key that does not exist succeeds.
  Future<Result<void, SecureStoreFailure>> delete(String key);
}
