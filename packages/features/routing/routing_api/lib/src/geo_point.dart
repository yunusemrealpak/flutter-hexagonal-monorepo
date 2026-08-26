import 'dart:math' as math;

import 'package:core_kernel/core_kernel.dart';
import 'package:meta/meta.dart';

import 'routing_failure.dart';

/// A point on the map, with the one piece of arithmetic routing needs.
///
/// `location_service` already publishes a `GeoFix`, and this is deliberately
/// not that type: a fix is what a device reported, complete with an accuracy
/// radius and the moment it was taken, and it belongs to a technology package.
/// A `GeoPoint` is a *place* — no accuracy, no timestamp, and a validating
/// factory, because a latitude of 91 is not somewhere a courier can be sent.
/// `routing_infrastructure` maps one into the other, which is the same
/// DTO-to-entity discipline rule 1.2.10 asks for at every boundary.
///
/// [distanceTo] lives here rather than in the optimiser, and that placement is
/// the interesting part. Two implementations of `RouteOptimizerPort` both need
/// to know how far apart two stops are, and if each carried its own haversine
/// they would eventually disagree about the length of the same route — which
/// is exactly the drift a contract kit cannot catch, because both would still
/// satisfy the port.
@immutable
final class GeoPoint {
  const GeoPoint._({required this.latitude, required this.longitude});

  /// Reads a point, refusing coordinates that are not on the earth.
  static Result<GeoPoint, RoutingFailure> at({
    required double latitude,
    required double longitude,
  }) {
    if (latitude.isNaN || latitude < -90 || latitude > 90) {
      return Failed(
        MalformedRouteValue(
          field: 'latitude',
          reason: '$latitude is outside -90..90',
        ),
      );
    }
    if (longitude.isNaN || longitude < -180 || longitude > 180) {
      return Failed(
        MalformedRouteValue(
          field: 'longitude',
          reason: '$longitude is outside -180..180',
        ),
      );
    }
    return Success(GeoPoint._(latitude: latitude, longitude: longitude));
  }

  /// Degrees north.
  final double latitude;

  /// Degrees east.
  final double longitude;

  /// The great-circle distance to [other], in metres.
  ///
  /// Haversine on a spherical earth. It is wrong by up to about 0.5% against
  /// the ellipsoid, which is a rounding error next to the fact that a courier
  /// drives on roads rather than along great circles — the number is used to
  /// *order* stops, and an ordering is unchanged by a uniform 0.5%.
  ///
  /// What it is not used for is an ETA a customer sees. That comes from the
  /// travel time an optimiser reports, which is a road network's answer rather
  /// than a straight line's.
  double distanceTo(GeoPoint other) {
    const earthRadiusMetres = 6371000.0;

    final dLat = _radians(other.latitude - latitude);
    final dLon = _radians(other.longitude - longitude);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_radians(latitude)) *
            math.cos(_radians(other.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    return earthRadiusMetres * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _radians(double degrees) => degrees * math.pi / 180;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeoPoint &&
          other.latitude == latitude &&
          other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'GeoPoint($latitude, $longitude)';
}
