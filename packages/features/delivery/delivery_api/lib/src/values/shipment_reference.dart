import 'package:core_kernel/core_kernel.dart';
import 'package:shipments_api/shipments_api.dart';

import '../failures/delivery_failure.dart';

/// Reads a shipment identifier out of the raw form a wire or a row carries it
/// in, and reports a bad one as a *delivery* failure.
///
/// The same anticorruption layer `shipments_api` publishes as
/// `CourierReference`, for the same two reasons.
///
/// A failure belongs to the package that owns the port. `ShipmentId.parse`
/// returns a `ShipmentFailure`, and a `DeliveryGateway` whose signature
/// promises `DeliveryFailure` may not hand one of shipments' back. Somebody
/// has to translate, and doing it here means it is translated once rather than
/// in every adapter that reads a shipment.
///
/// And `delivery_infrastructure` may not depend on a foreign `_api` at all —
/// section 2 of docs/DEPENDENCY_RULES.md. Without this function an adapter
/// would have no way to rebuild the `ShipmentId` delivery's own contract is
/// expressed in, and the pressure would be to widen that row. What the adapter
/// needs is not shipments' vocabulary but delivery's answer to "is this a
/// parcel we can name?", and that answer belongs here.
abstract final class ShipmentReference {
  /// Reads [raw] as the identifier of a shipment.
  static Result<ShipmentId, DeliveryFailure> parse(String raw) =>
      ShipmentId.parse(raw).mapFailure(
        (failure) =>
            MalformedDeliveryValue(field: 'shipment', reason: '$failure'),
      );
}
