import 'package:core_kernel/core_kernel.dart';
import 'package:shipments_api/shipments_api.dart';

import 'geo_point.dart';
import 'routing_failure.dart';
import 'service_time.dart';
import 'stop_id.dart';
import 'travel_window.dart';

/// One place a courier has to be, and everything a route needs to know about
/// being there.
///
/// An `Entity`: equality is by [id], because a stop whose window was corrected
/// at eleven o'clock is still the same stop. Two stops at the same address are
/// two stops — a building with a pharmacy and a dentist in it is two
/// deliveries, and a routing feature that merged them would drop one.
///
/// [shipmentId] is a `ShipmentId`, from `shipments_api`, and that edge is the
/// one worth noticing: a foreign `_api`, which section 2 allows, and the only
/// vocabulary for "which parcel" that both features can agree on. It is
/// nullable because not every stop has a parcel behind it — a depot, a fuel
/// stop and a break are all places on a route.
///
/// [address] is an `AddressPoint`, also from `shipments_api`, and it may not
/// be geocoded. [placed] is where that shows up: a stop the optimiser cannot
/// place is reported by name rather than guessed at, because a route planned
/// around a guessed coordinate sends a courier to the wrong street with full
/// confidence.
final class Stop extends Entity<StopId> {
  /// Creates a stop.
  const Stop({
    required super.id,
    required this.address,
    this.shipmentId,
    this.serviceTime = ServiceTime.standard,
    this.window,
  });

  /// Where it is, in the words shipments uses.
  final AddressPoint address;

  /// Which parcel it is about, where one is.
  final ShipmentId? shipmentId;

  /// How long the courier will be there once they arrive.
  final ServiceTime serviceTime;

  /// When the place will accept a delivery, or `null` for anytime.
  final TravelWindow? window;

  /// The point on the map, or a failure naming this stop.
  ///
  /// Returns a `Result` rather than a nullable point, because every caller
  /// that needs a coordinate needs to *report* the one it could not get, and a
  /// null forces each of them to invent the same message.
  Result<GeoPoint, RoutingFailure> get placed {
    final latitude = address.latitude;
    final longitude = address.longitude;
    if (latitude == null || longitude == null) {
      return Failed(
        StopNotGeocoded(stopId: id.value, address: address.formatted),
      );
    }
    return GeoPoint.at(latitude: latitude, longitude: longitude);
  }

  /// Whether a courier arriving at [instant] has missed this stop's window.
  ///
  /// `false` when the stop has no window: a place with no closing time cannot
  /// be arrived at late.
  bool isLateAt(DateTime instant) => window?.isLateAt(instant) ?? false;

  /// Returns a copy with the given fields replaced.
  Stop copyWith({
    AddressPoint? address,
    ServiceTime? serviceTime,
    TravelWindow? window,
  }) => Stop(
    id: id,
    address: address ?? this.address,
    shipmentId: shipmentId,
    serviceTime: serviceTime ?? this.serviceTime,
    window: window ?? this.window,
  );

  @override
  String toString() => 'Stop(${id.value}, ${address.formatted})';
}
