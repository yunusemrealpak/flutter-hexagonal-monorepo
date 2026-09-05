import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';
import 'package:shipments_api/shipments_api.dart';

import '../../entities/delivery_attempt.dart';
import '../../failures/delivery_failure.dart';
import '../../values/delivery_grade.dart';

/// Arriving at a door, from the device that is standing at it.
///
/// One operation, and it is alone here for the same reason `RouteFollowing`
/// is separate from `RoutePlanning`: [startAttempt] asks a `GeoFencePort`
/// whether *this device* is inside the delivery area. A desk composing it
/// would be asking whether the desk is at the consignee's address.
///
/// Everything that happens *after* arriving — closing the attempt, reading it
/// back — is not device-bound, and lives in `DeliverySettlement` and
/// `DeliveryHistory` so that an operator can correct a record without an app
/// pretending to hold a position it does not have.
abstract interface class DeliveryExecution {
  /// Opens an attempt at [shipment]'s address.
  ///
  /// Refuses when the courier is not there: the geofence is asked first, and
  /// an attempt started from three streets away is `OutsideDeliveryArea`
  /// rather than a record nobody can trust. `grade` is delivery's own word for
  /// how much proof the parcel is worth, supplied by whoever knows what is in
  /// it.
  Future<Result<DeliveryAttempt, DeliveryFailure>> startAttempt({
    required ShipmentId shipment,
    required ActorId courier,
    DeliveryGrade grade = DeliveryGrade.standard,
  });
}
