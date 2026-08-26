import 'package:core_kernel/core_kernel.dart';

import 'vehicle_inventory_failure.dart';

/// Whether parcels are going into the van or coming out of it.
///
/// The same reconciliation runs both ways and means opposite things, which is
/// why this is a field on the count rather than two entities. A parcel on the
/// manifest that nobody scanned is *missing* when loading and *delivered or
/// still aboard* when unloading — the arithmetic is identical and the sentence
/// a dispatcher reads is not, so the direction has to survive into the record.
enum LoadDirection {
  /// Parcels are being scanned into the vehicle at the depot.
  loading,

  /// Parcels are being scanned back out at the end of the round.
  unloading;

  /// Reads a direction from its stored spelling.
  static Result<LoadDirection, VehicleInventoryFailure> parse(String raw) {
    for (final value in values) {
      if (value.name == raw) {
        return Success(value);
      }
    }
    return Failed(
      MalformedCount(
        field: 'direction',
        reason: '"$raw" is not one of ${values.map((v) => v.name).join(', ')}',
      ),
    );
  }
}
