import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';

import 'routing_failure.dart';

/// Reads a courier identifier out of the raw form a wire or a row carries it
/// in, and reports a bad one as a *routing* failure.
///
/// The same shape as `CourierReference` in `shipments_api`, and here for the
/// same two reasons.
///
/// The first is a rule: a failure belongs to the package that owns the port.
/// `ActorId.parse` returns an `IdentityFailure`, and a `RouteCache` whose
/// signature promises `RoutingFailure` may not hand one of identity's back.
/// Somebody has to translate, and doing it here means it is translated once
/// rather than in every adapter that reads a courier.
///
/// The second is what that rule protects. `routing_infrastructure` may not
/// depend on a foreign `_api` at all — section 2 — and without this function
/// an adapter would have no way to rebuild the `ActorId` routing's own
/// contract is expressed in. What the adapter needs is not identity's
/// vocabulary but routing's answer to "is this a courier we can name?", and
/// that answer belongs here.
///
/// This is an anticorruption layer placed in the consuming feature's own
/// contract. `routing_api` is the one layer allowed to see identity, so it is
/// the one layer that can do the translating.
abstract final class CourierReference {
  /// Reads [raw] as the identifier of a courier.
  static Result<ActorId, RoutingFailure> parse(String raw) =>
      ActorId.parse(raw).mapFailure(
        (failure) => MalformedRouteValue(
          field: 'courier',
          reason: '$failure',
        ),
      );
}
