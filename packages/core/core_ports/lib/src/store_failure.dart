import 'package:core_kernel/core_kernel.dart';
import 'key_value_store.dart';

/// Why a [KeyValueStore] operation did not complete.
///
/// Sealed, so a caller that handles one case is forced by the compiler to say
/// what it does about the others. This is the shape every failure type in the
/// workspace takes.
sealed class StoreFailure extends Failure {
  const StoreFailure();
}

/// The storage backend could not be reached or opened.
final class StoreUnavailable extends StoreFailure {
  /// Records that the backend was unreachable, with an optional [detail] for
  /// the log.
  const StoreUnavailable({this.detail});

  /// Adapter-supplied context. Never rendered to a user.
  final String? detail;

  @override
  String toString() => 'StoreUnavailable(${detail ?? 'no detail'})';
}

/// The value was found but could not be read back in the expected shape.
///
/// Usually a schema change that shipped without a migration.
final class StoreCorrupted extends StoreFailure {
  /// Records that [key] held a value the adapter could not decode.
  const StoreCorrupted(this.key);

  /// The key whose value could not be decoded.
  final String key;

  @override
  String toString() => 'StoreCorrupted($key)';
}

/// The write could not be completed because there is no room for it.
final class StoreOutOfSpace extends StoreFailure {
  /// Records that the device rejected the write for lack of space.
  const StoreOutOfSpace();

  @override
  String toString() => 'StoreOutOfSpace()';
}
