import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:core_testing/src/in_memory_key_value_store.dart';

/// A [SecureStore] backed by a map, with a way to make the next call fail.
///
/// Separate from [InMemoryKeyValueStore] rather than a generic shared with it,
/// because the two ports fail differently and the whole value of this fake is
/// that a test can produce a locked keychain or invalidated key material —
/// states plain storage has no equivalent for.
final class InMemorySecureStore implements SecureStore {
  final Map<String, String> _entries = {};
  final List<SecureStoreFailure> _queuedFailures = [];

  /// A read-only view of what is currently stored.
  ///
  /// Present so a test can assert that a refresh token was cleared on sign
  /// out. Real secure storage offers no such view, which is exactly why the
  /// assertion has to happen against the fake.
  Map<String, String> get entries => Map.unmodifiable(_entries);

  /// Makes the next call return [failure] instead of doing its job.
  void failNextWith(SecureStoreFailure failure) => _queuedFailures.add(failure);

  SecureStoreFailure? _takeFailure() =>
      _queuedFailures.isEmpty ? null : _queuedFailures.removeAt(0);

  @override
  Future<Result<String?, SecureStoreFailure>> read(String key) async {
    final failure = _takeFailure();
    if (failure != null) {
      return Failed(failure);
    }
    return Success(_entries[key]);
  }

  @override
  Future<Result<void, SecureStoreFailure>> write(
    String key,
    String value,
  ) async {
    final failure = _takeFailure();
    if (failure != null) {
      return Failed(failure);
    }
    _entries[key] = value;
    return const Success(null);
  }

  @override
  Future<Result<void, SecureStoreFailure>> delete(String key) async {
    final failure = _takeFailure();
    if (failure != null) {
      return Failed(failure);
    }
    _entries.remove(key);
    return const Success(null);
  }
}
