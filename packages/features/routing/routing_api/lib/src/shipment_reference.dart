import 'package:core_kernel/core_kernel.dart';
import 'package:shipments_api/shipments_api.dart';

import 'routing_failure.dart';

/// Reads the identifier of the parcel a stop is about, and reports a bad one
/// as a *routing* failure.
///
/// The counterpart to [CourierReference], and the second half of what keeps
/// `routing_infrastructure` free of foreign dependencies.
///
/// **A `ShipmentId` crosses and a `Shipment` does not**, which is the line
/// section 2.1 draws. An identifier is a single value whose whole content is
/// "which one"; it is the reference a bounded context is supposed to hold to
/// another. Anything with behaviour or more than one field is a model, and a
/// routing package that carried one would be carrying a concept shipments
/// owns — with the reconciliation landing in whichever adapter noticed first.
///
/// Absent is a success carrying `null`, because not every stop has a parcel
/// behind it. A depot, a fuel stop and a break are all places on a route.
abstract final class ShipmentReference {
  /// Reads [raw] as the identifier of a shipment.
  static Result<ShipmentId, RoutingFailure> parse(String raw) =>
      ShipmentId.parse(raw).mapFailure(
        (failure) => MalformedRouteValue(
          field: 'shipmentId',
          reason: '$failure',
        ),
      );

  /// Reads [raw] where a stop may have no parcel behind it.
  ///
  /// Present but unreadable is still a failure. A route that quietly dropped
  /// the link between a stop and its parcel would leave a courier standing at
  /// an address with nothing to scan.
  static Result<ShipmentId?, RoutingFailure> parseOptional(String? raw) =>
      raw == null ? const Success(null) : parse(raw);
}
