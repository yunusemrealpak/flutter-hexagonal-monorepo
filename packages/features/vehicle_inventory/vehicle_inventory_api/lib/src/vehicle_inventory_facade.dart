import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';
import 'package:shipments_api/shipments_api.dart';

import 'load_count.dart';
import 'load_count_id.dart';
import 'load_direction.dart';
import 'vehicle_inventory_failure.dart';

/// What the rest of the product may ask vehicle inventory to do.
///
/// A driving port, speaking in `ActorId` and `ShipmentId` because every caller
/// already holds them. The driven ports beside it speak in `String`.
abstract interface class VehicleInventoryFacade {
  /// Opens a count of [courier]'s van, against the depot's manifest.
  Future<Result<LoadCount, VehicleInventoryFailure>> startCount({
    required ActorId courier,
    required LoadDirection direction,
  });

  /// Records one scan.
  ///
  /// Answers with the count as it now stands, so a screen can redraw without
  /// re-reading. Scanning the same parcel twice succeeds and changes nothing.
  Future<Result<LoadCount, VehicleInventoryFailure>> scan({
    required LoadCountId count,
    required ShipmentId shipment,
  });

  /// Closes the count, whether or not it reconciles.
  Future<Result<LoadCount, VehicleInventoryFailure>> close(LoadCountId count);

  /// The count somebody is in the middle of, if there is one.
  ///
  /// Answers `null` rather than a failure when there is none: a courier who
  /// has not started counting is in an ordinary state, not an error.
  Future<Result<LoadCount?, VehicleInventoryFailure>> openCountFor(
    ActorId courier,
  );
}
