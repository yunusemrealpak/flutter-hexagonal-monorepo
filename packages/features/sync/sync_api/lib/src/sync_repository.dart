import 'package:core_kernel/core_kernel.dart';

import 'sync_failure.dart';

/// What sync needs from the outside world, in the product's words.
///
/// A port, not a technology contract: it says nothing about HTTP, a database
/// or a device. An adapter in an implementation package answers it *using* a
/// technology, and an app's composition root decides which one.
///
/// The method returns a [Result] because it can fail. Rule 1.2.9 forbids an
/// exception crossing this boundary — an adapter catches whatever its
/// technology throws and returns a [SyncFailure] instead.
abstract interface class SyncRepository {
  /// Loads the record stored under [id].
  Future<Result<String, SyncFailure>> byId(String id);
}
