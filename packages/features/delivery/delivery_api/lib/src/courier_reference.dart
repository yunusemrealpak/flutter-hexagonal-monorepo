import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';

import 'delivery_failure.dart';

/// Reads a courier identifier out of the raw form a wire or a row carries it
/// in, and reports a bad one as a *delivery* failure.
///
/// The companion of `ShipmentReference`, and here for the same reason: an
/// attempt names the courier who made it, an adapter has to rebuild that name
/// from a stored row, and `delivery_infrastructure` may see neither
/// `identity_api` nor anybody else's failure type.
abstract final class CourierReference {
  /// Reads [raw] as the identifier of a courier.
  static Result<ActorId, DeliveryFailure> parse(String raw) =>
      ActorId.parse(raw).mapFailure(
        (failure) =>
            MalformedDeliveryValue(field: 'courier', reason: '$failure'),
      );
}
