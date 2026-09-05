import 'package:core_kernel/core_kernel.dart';
import 'package:shipments_api/shipments_api.dart';

import '../failures/payments_failure.dart';

/// Reads a shipment identifier out of the raw form a wire or a row carries it
/// in, and reports a bad one as a *payments* failure.
///
/// The same anticorruption layer `shipments_api` publishes as
/// `CourierReference` and `delivery_api` as its own `ShipmentReference`, for
/// the same two reasons.
///
/// A failure belongs to the package that owns the port: `ShipmentId.parse`
/// returns a `ShipmentFailure`, and a `PaymentsGateway` whose signature
/// promises `PaymentsFailure` may not hand one of shipments' back.
///
/// And `payments_infrastructure` may not depend on a foreign `_api` at all —
/// section 2. Without this function an adapter would have no way to rebuild
/// the `ShipmentId` payments' own contract is expressed in, and the pressure
/// would be to widen that row.
abstract final class ShipmentReference {
  /// Reads [raw] as the identifier of a shipment.
  static Result<ShipmentId, PaymentsFailure> parse(String raw) =>
      ShipmentId.parse(raw).mapFailure(
        (failure) =>
            MalformedPaymentValue(field: 'shipment', reason: '$failure'),
      );
}
