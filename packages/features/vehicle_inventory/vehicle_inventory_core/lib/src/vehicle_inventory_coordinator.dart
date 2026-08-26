import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';
import 'package:shipments_api/shipments_api.dart';
import 'package:vehicle_inventory_api/vehicle_inventory_api.dart';

import 'close_count.dart';
import 'find_open_count.dart';
import 'record_scan.dart';
import 'start_count.dart';

/// The one implementation of `VehicleInventoryFacade`.
///
/// It composes use cases and holds no rule of its own.
final class VehicleInventoryCoordinator implements VehicleInventoryFacade {
  /// Creates the coordinator over its use cases.
  const VehicleInventoryCoordinator({
    required this._start,
    required this._record,
    required this._close,
    required this._find,
  });

  final StartCount _start;
  final RecordScan _record;
  final CloseCount _close;
  final FindOpenCount _find;

  @override
  Future<Result<LoadCount, VehicleInventoryFailure>> startCount({
    required ActorId courier,
    required LoadDirection direction,
  }) => _start(StartCountCommand(courier: courier, direction: direction));

  @override
  Future<Result<LoadCount, VehicleInventoryFailure>> scan({
    required LoadCountId count,
    required ShipmentId shipment,
  }) => _record(RecordScanCommand(count: count, shipment: shipment));

  @override
  Future<Result<LoadCount, VehicleInventoryFailure>> close(LoadCountId count) =>
      _close(count);

  @override
  Future<Result<LoadCount?, VehicleInventoryFailure>> openCountFor(
    ActorId courier,
  ) => _find(courier);
}
