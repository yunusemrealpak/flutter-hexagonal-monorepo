import 'package:core_kernel/core_kernel.dart';

import 'routing_failure.dart';

/// Identifies one place a courier has to be, for the life of a route.
///
/// Separate from `ShipmentId` on purpose. Most stops exist because a parcel
/// goes there, but not all of them: a depot, a fuel stop and a break are
/// places on a route with no shipment behind them, and a route whose
/// identifiers were shipment identifiers could not express any of the three.
///
/// It also keeps the two features honest about which vocabulary they are in.
/// A `Stop` carries the `ShipmentId` it serves as a *field*, which reads as
/// "this stop is about that parcel" rather than "this stop is that parcel".
final class StopId extends ValueObject<String> {
  const StopId._(super.value);

  /// Reads a stop identifier from [raw].
  static Result<StopId, RoutingFailure> parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const Failed(
        MalformedRouteValue(field: 'stopId', reason: 'is empty'),
      );
    }
    return Success(StopId._(trimmed));
  }
}
