import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';
import 'package:shipments_api/shipments_api.dart';
import 'package:vehicle_inventory_api/vehicle_inventory_api.dart';

/// A fixed instant, so that no test in this package needs a clock.
final DateTime started = DateTime.utc(2026, 3, 4, 6, 30);

/// The courier every fixture belongs to.
final ActorId courier =
    (ActorId.parse('courier-7') as Success<ActorId, IdentityFailure>).value;

/// Reads a shipment identifier, throwing on an invalid fixture.
ShipmentId parcel(String raw) =>
    (ShipmentId.parse(raw) as Success<ShipmentId, ShipmentFailure>).value;

/// Reads a count identifier, throwing on an invalid fixture.
LoadCountId countId(String raw) =>
    (LoadCountId.parse(raw) as Success<LoadCountId, VehicleInventoryFailure>)
        .value;

/// An open count of three parcels.
LoadCount open({Set<ShipmentId>? manifest}) =>
    (LoadCount.opened(
              id: countId('CNT-1'),
              courier: courier,
              direction: LoadDirection.loading,
              manifest:
                  manifest ??
                  {parcel('SHP-1'), parcel('SHP-2'), parcel('SHP-3')},
              startedAt: started,
            )
            as Success<LoadCount, VehicleInventoryFailure>)
        .value;

/// The count behind a successful result.
LoadCount valueOf(Result<LoadCount, VehicleInventoryFailure> result) =>
    (result as Success<LoadCount, VehicleInventoryFailure>).value;

/// The failure behind an unsuccessful one.
VehicleInventoryFailure failureOf(
  Result<LoadCount, VehicleInventoryFailure> result,
) => (result as Failed<LoadCount, VehicleInventoryFailure>).failure;
