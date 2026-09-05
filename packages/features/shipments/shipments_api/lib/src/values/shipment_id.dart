import 'package:core_kernel/core_kernel.dart';

import '../failures/shipment_failure.dart';

/// Identifies one shipment for the life of the operation.
///
/// Hand-written for the reason every value object in this workspace is: the
/// private constructor plus the validating factory are what make an invalid
/// identifier unconstructible. A generated class publishes its constructor,
/// and validation that can be bypassed is validation nobody can rely on.
final class ShipmentId extends ValueObject<String> {
  const ShipmentId._(super.value);

  /// Reads a shipment identifier from [raw].
  static Result<ShipmentId, ShipmentFailure> parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return Failed(MalformedShipmentId(raw));
    }
    return Success(ShipmentId._(trimmed));
  }
}
