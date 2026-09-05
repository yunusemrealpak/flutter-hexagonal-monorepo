import 'package:core_kernel/core_kernel.dart';

import '../failures/vehicle_inventory_failure.dart';

/// Identifies one count of one vehicle.
///
/// Minted per count, never derived from the courier or the day. A van is
/// counted twice a day in the ordinary case and three times when something
/// went wrong in the morning, and an identifier derived from courier and date
/// would make the second count overwrite the first — which is precisely the
/// record somebody needs when a parcel is missing.
final class LoadCountId extends ValueObject<String> {
  const LoadCountId._(super.value);

  /// Reads a count identifier from [raw].
  static Result<LoadCountId, VehicleInventoryFailure> parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const Failed(MalformedCount(field: 'id', reason: 'it is empty'));
    }
    return Success(LoadCountId._(trimmed));
  }
}
