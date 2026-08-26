import 'package:core_kernel/core_kernel.dart';

import 'load_count.dart';
import 'vehicle_inventory_failure.dart';

/// Where counts are kept.
///
/// Whole counts in and out, never fields. An interface with `addScan` on it
/// would put the idempotence rule in the adapter, where `LoadCount`'s own
/// guards could not reach it.
abstract interface class LoadCountStore {
  /// Every count this device knows about, newest first.
  Future<Result<List<LoadCount>, VehicleInventoryFailure>> all();

  /// Records a new count.
  Future<Result<void, VehicleInventoryFailure>> open(LoadCount count);

  /// Replaces the count with the same identifier.
  ///
  /// Fails with [CountMissing] when there is nothing to replace.
  Future<Result<void, VehicleInventoryFailure>> update(LoadCount count);
}
