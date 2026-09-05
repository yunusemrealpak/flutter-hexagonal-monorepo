import 'package:core_kernel/core_kernel.dart';
import 'package:shipments_api/shipments_api.dart';

import '../failures/routing_failure.dart';
import '../values/geo_point.dart';
import '../values/service_time.dart';
import '../values/shipment_reference.dart';
import '../values/stop_id.dart';
import '../values/travel_window.dart';

/// One place a courier has to be, and everything a route needs to know about
/// being there.
///
/// An `Entity`: equality is by [id], because a stop whose window was corrected
/// at eleven o'clock is still the same stop. Two stops at the same address are
/// two stops — a building with a pharmacy and a dentist in it is two
/// deliveries, and a routing feature that merged them would drop one.
///
/// **A stop holds a `GeoPoint` and a label, not shipments' `AddressPoint`.**
/// That is section 2.1's rule about what may cross a feature boundary, and
/// this type is where the repository learned it. An `AddressPoint` is three
/// fields, a validation and a display string — a concept `shipments` owns,
/// answering *"where is this parcel going"*. Routing's question is *"what
/// point do I measure from"*, and the answer to that is its own `GeoPoint`.
///
/// Carrying the foreign model instead cost three things at once, and none of
/// them looked related. Every stop had to answer "do you have coordinates?" on
/// every read; `StopNotGeocoded` ended up in the contract three optimisers are
/// held to; and `routing_infrastructure` could not build a stop without
/// reaching for `shipments_api`. Only the last one showed up as a violation.
///
/// [shipmentId] is a `ShipmentId` — an identifier, which is precisely the
/// reference one bounded context is supposed to hold to another. It is
/// nullable because not every stop has a parcel behind it: a depot, a fuel
/// stop and a break are all places on a route.
final class Stop extends Entity<StopId> {
  const Stop._({
    required super.id,
    required this.at,
    required this.label,
    required this.serviceTime,
    this.shipmentId,
    this.window,
  });

  /// Reads a stop from the raw form a manifest or a stored row carries it in.
  ///
  /// The only way to make one, and the only place a stop can be refused. A
  /// route is built from stops that already exist, so by the time an optimiser
  /// or a plan sees one, every question about whether it is usable has been
  /// answered — which is what makes the invalid state unconstructible rather
  /// than merely reported.
  ///
  /// Missing coordinates are a `StopNotGeocoded` naming the stop. Guessing a
  /// position instead would send a courier to the wrong street with full
  /// confidence.
  static Result<Stop, RoutingFailure> place({
    required String id,
    required String label,
    required double? latitude,
    required double? longitude,
    String? shipmentId,
    ServiceTime serviceTime = ServiceTime.standard,
    TravelWindow? window,
  }) {
    final StopId stopId;
    switch (StopId.parse(id)) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        stopId = value;
    }

    final trimmed = label.trim();
    if (trimmed.isEmpty) {
      return Failed(
        MalformedRouteValue(
          field: 'stop.label',
          reason: 'is empty for ${stopId.value}',
        ),
      );
    }

    if (latitude == null || longitude == null) {
      return Failed(StopNotGeocoded(stopId: stopId.value, address: trimmed));
    }

    final GeoPoint at;
    switch (GeoPoint.at(latitude: latitude, longitude: longitude)) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        at = value;
    }

    final ShipmentId? parcel;
    switch (ShipmentReference.parseOptional(shipmentId)) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        parcel = value;
    }

    return Success(
      Stop._(
        id: stopId,
        at: at,
        label: trimmed,
        serviceTime: serviceTime,
        shipmentId: parcel,
        window: window,
      ),
    );
  }

  /// Where it is.
  final GeoPoint at;

  /// What a courier reads on a stop list.
  ///
  /// A plain string, and deliberately not a structured address: routing does
  /// not sort by street, search by postcode or validate a door number. It
  /// draws this and drives to [at].
  final String label;

  /// How long the courier will be there once they arrive.
  final ServiceTime serviceTime;

  /// Which parcel it is about, where one is.
  final ShipmentId? shipmentId;

  /// When the place will accept a delivery, or `null` for anytime.
  final TravelWindow? window;

  /// Whether a courier arriving at [instant] has missed this stop's window.
  ///
  /// `false` when the stop has no window: a place with no closing time cannot
  /// be arrived at late.
  bool isLateAt(DateTime instant) => window?.isLateAt(instant) ?? false;

  /// Returns a copy with the given fields replaced.
  Stop copyWith({ServiceTime? serviceTime, TravelWindow? window}) => Stop._(
    id: id,
    at: at,
    label: label,
    serviceTime: serviceTime ?? this.serviceTime,
    shipmentId: shipmentId,
    window: window ?? this.window,
  );

  @override
  String toString() => 'Stop(${id.value}, $label)';
}
