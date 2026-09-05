import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';

import '../failures/payments_failure.dart';

/// Reads a courier identifier out of the raw form a wire or a row carries it
/// in, and reports a bad one as a *payments* failure.
///
/// The companion of `ShipmentReference`. A settlement names the courier whose
/// day it is, an adapter has to rebuild that name from a stored row, and
/// `payments_infrastructure` may see neither `identity_api` nor anybody else's
/// failure type.
abstract final class CourierReference {
  /// Reads [raw] as the identifier of a courier.
  static Result<ActorId, PaymentsFailure> parse(String raw) =>
      ActorId.parse(raw).mapFailure(
        (failure) =>
            MalformedPaymentValue(field: 'courier', reason: '$failure'),
      );
}
