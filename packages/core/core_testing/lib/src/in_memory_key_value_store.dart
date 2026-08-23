import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';

/// A [KeyValueStore] backed by a map, with a way to make the next call fail.
///
/// This is a fake and not a mock: it really stores, really reads back, and
/// really reports a missing key as a successful read of `null`. A test that
/// writes and then reads gets what it wrote, which means the test exercises
/// the caller's logic rather than a script of expected calls.
///
/// [failNextWith] is what makes the failure branches testable without a
/// second, differently-behaved fake. Failure is part of the contract, so the
/// fake that stands in for the contract has to be able to produce it.
final class InMemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> _entries = {};
  final List<StoreFailure> _queuedFailures = [];

  /// A read-only view of what is currently stored.
  Map<String, String> get entries => Map.unmodifiable(_entries);

  /// Makes the next call — whichever it is — return [failure] instead of
  /// doing its job. Queue several to fail several calls in a row.
  void failNextWith(StoreFailure failure) => _queuedFailures.add(failure);

  StoreFailure? _takeFailure() =>
      _queuedFailures.isEmpty ? null : _queuedFailures.removeAt(0);

  @override
  Future<Result<String?, StoreFailure>> read(String key) async {
    final failure = _takeFailure();
    if (failure != null) {
      return Failed(failure);
    }
    return Success(_entries[key]);
  }

  @override
  Future<Result<void, StoreFailure>> write(String key, String value) async {
    final failure = _takeFailure();
    if (failure != null) {
      return Failed(failure);
    }
    _entries[key] = value;
    return const Success(null);
  }

  @override
  Future<Result<void, StoreFailure>> delete(String key) async {
    final failure = _takeFailure();
    if (failure != null) {
      return Failed(failure);
    }
    _entries.remove(key);
    return const Success(null);
  }

  @override
  Future<Result<Set<String>, StoreFailure>> keys() async {
    final failure = _takeFailure();
    if (failure != null) {
      return Failed(failure);
    }
    return Success(_entries.keys.toSet());
  }
}
