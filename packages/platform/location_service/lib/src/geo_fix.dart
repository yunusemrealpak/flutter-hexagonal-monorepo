/// A position, as the device reported it.
///
/// Deliberately not a domain type. `delivery` and `routing` will declare their
/// own coordinate types in their `_api` packages, with their own invariants —
/// a proof-of-delivery location that must be within a tolerance of an address,
/// a route waypoint that must be on a road. Their `_infrastructure` packages
/// map this into those, which is the same DTO-to-entity discipline rule 1.2.10
/// asks for at every other boundary.
///
/// [capturedAt] is the moment the *device* fixed the position, not the moment
/// the code read it. The difference matters offline: a fix taken in a basement
/// twenty minutes ago and delivered when signal returns has to be recognisable
/// as stale, and only its own timestamp can say so.
final class GeoFix {
  /// Records a position at [latitude], [longitude] as fixed at [capturedAt].
  const GeoFix({
    required this.latitude,
    required this.longitude,
    required this.accuracyMetres,
    required this.capturedAt,
  });

  /// Degrees, normalised to the interval -90.0 to 90.0.
  final double latitude;

  /// Degrees, normalised to the interval -180.0 to 180.0.
  final double longitude;

  /// The radius, in metres, of the 68% confidence circle around the position.
  ///
  /// A geofence check that ignores this compares a point against a boundary
  /// when what it has is a disc.
  final double accuracyMetres;

  /// When the device fixed this position, in UTC.
  final DateTime capturedAt;

  @override
  String toString() =>
      'GeoFix($latitude, $longitude, ±${accuracyMetres}m, $capturedAt)';
}
