import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/src/store_failure.dart';

/// Reads and writes small values that survive a restart.
///
/// For preferences, cursors and cached scalars — not for domain data, which
/// belongs behind a feature's own outbound port where it can be typed and
/// versioned. A feature that reaches for this port to persist entities has
/// skipped designing its repository.
///
/// Every method returns a [Result] because every one of them touches a disk
/// that can be full, locked or corrupt. Nothing here throws: that is invariant
/// 1.2.9, and it is what lets a caller handle storage failure as a branch
/// rather than as an interruption.
abstract interface class KeyValueStore {
  /// Reads the value at [key], or `null` when nothing is stored there.
  ///
  /// A missing key is a successful read of nothing, not a failure. Only an
  /// unreachable or unreadable store fails.
  Future<Result<String?, StoreFailure>> read(String key);

  /// Stores [value] at [key], replacing whatever was there.
  Future<Result<void, StoreFailure>> write(String key, String value);

  /// Removes [key]. Removing a key that does not exist succeeds.
  Future<Result<void, StoreFailure>> delete(String key);

  /// Every key currently stored.
  ///
  /// Present for the maintenance paths — clearing a namespace on sign-out,
  /// reporting cache size. Not for iterating domain data.
  Future<Result<Set<String>, StoreFailure>> keys();
}
