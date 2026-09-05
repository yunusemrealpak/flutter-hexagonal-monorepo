import 'package:core_kernel/core_kernel.dart';
import 'package:meta/meta.dart';

import '../failures/shipment_failure.dart';

/// Where a shipment is going: a written address and, when it is known, the
/// point on the map it resolved to.
///
/// Hand-written rather than generated, and the reason is the line this
/// workspace draws around `freezed`: a generated class publishes its
/// constructor, and this type has something to check. A latitude of 91 is not
/// a value the domain has an opinion about — it is not a place.
@immutable
final class AddressPoint {
  const AddressPoint._({
    required this.formatted,
    required this.latitude,
    required this.longitude,
  });

  /// Reads an address, optionally with the coordinates it geocoded to.
  ///
  /// Coordinates are optional together rather than separately: a latitude
  /// without a longitude is not half a location, it is a bug that would
  /// otherwise travel as far as a map pin at the equator.
  static Result<AddressPoint, ShipmentFailure> create({
    required String formatted,
    double? latitude,
    double? longitude,
  }) {
    final trimmed = formatted.trim();
    if (trimmed.isEmpty) {
      return const Failed(
        MalformedValue(field: 'address', reason: 'is empty'),
      );
    }
    if ((latitude == null) != (longitude == null)) {
      return const Failed(
        MalformedValue(
          field: 'address',
          reason: 'latitude and longitude are given together or not at all',
        ),
      );
    }
    if (latitude != null && (latitude < -90 || latitude > 90)) {
      return Failed(
        MalformedValue(
          field: 'address.latitude',
          reason: '$latitude is outside -90..90',
        ),
      );
    }
    if (longitude != null && (longitude < -180 || longitude > 180)) {
      return Failed(
        MalformedValue(
          field: 'address.longitude',
          reason: '$longitude is outside -180..180',
        ),
      );
    }
    return Success(
      AddressPoint._(
        formatted: trimmed,
        latitude: latitude,
        longitude: longitude,
      ),
    );
  }

  /// The address as it would be written on the label.
  final String formatted;

  /// Degrees north, or `null` when the address has not been geocoded.
  final double? latitude;

  /// Degrees east, or `null` when the address has not been geocoded.
  final double? longitude;

  /// Whether this address resolved to a point on the map.
  bool get isGeocoded => latitude != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddressPoint &&
          other.formatted == formatted &&
          other.latitude == latitude &&
          other.longitude == longitude;

  @override
  int get hashCode => Object.hash(formatted, latitude, longitude);

  @override
  String toString() => 'AddressPoint($formatted)';
}
