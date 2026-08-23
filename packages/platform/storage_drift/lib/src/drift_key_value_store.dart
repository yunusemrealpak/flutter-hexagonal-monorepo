import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'key_value_dao.dart';
import 'sqlite_store_failure.dart';

/// The [KeyValueStore] the shipped applications run on.
///
/// This class is the boundary. Below it, [KeyValueDao] speaks SQL and is
/// allowed to throw; above it, a caller gets a `Result` and never sees a
/// `SqliteException`. Every method here is the same three lines — do the work,
/// catch, translate — and that repetition is the shape invariant 1.2.9 takes
/// in an adapter.
///
/// The [Clock] is injected rather than read, so `updatedAt` is a value a test
/// chooses instead of the moment the test happened to run. That is rule A1,
/// and this is the first place in the workspace where obeying it costs a
/// constructor parameter.
///
/// [namespace] is what stops two features that both store `cursor` from
/// overwriting each other, and what lets sign-out clear one feature's values
/// without touching another's.
final class DriftKeyValueStore implements KeyValueStore {
  /// Stores through the given data access object, stamping every write
  /// with the injected clock.
  const DriftKeyValueStore(
    this._dao,
    this._clock, {
    this.namespace = 'default',
  });

  final KeyValueDao _dao;
  final Clock _clock;

  /// Which subsystem's values this store reads and writes.
  final String namespace;

  @override
  Future<Result<String?, StoreFailure>> read(String key) async {
    try {
      final entry = await _dao.find(namespace, key);
      // A missing key is a successful read of nothing. Only an unreachable or
      // unreadable store fails, which is what the port's documentation
      // promises and what callers branch on.
      return Success(entry?.value);
    } on Object catch (error) {
      return Failed(storeFailureFrom(error, key: key));
    }
  }

  @override
  Future<Result<void, StoreFailure>> write(String key, String value) async {
    try {
      await _dao.put(
        namespace: namespace,
        key: key,
        value: value,
        updatedAt: _clock.now(),
      );
      return const Success(null);
    } on Object catch (error) {
      return Failed(storeFailureFrom(error, key: key));
    }
  }

  @override
  Future<Result<void, StoreFailure>> delete(String key) async {
    try {
      await _dao.remove(namespace, key);
      return const Success(null);
    } on Object catch (error) {
      return Failed(storeFailureFrom(error, key: key));
    }
  }

  @override
  Future<Result<Set<String>, StoreFailure>> keys() async {
    try {
      return Success(await _dao.keysIn(namespace));
    } on Object catch (error) {
      // No single key is implicated, so the namespace is what a corruption
      // failure names.
      return Failed(storeFailureFrom(error, key: namespace));
    }
  }
}
