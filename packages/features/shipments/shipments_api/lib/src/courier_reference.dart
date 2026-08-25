import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';

import 'shipment_failure.dart';

/// Reads a courier identifier out of the raw form a wire or a row carries it
/// in, and reports a bad one as a *shipments* failure.
///
/// It would be easy to leave this to whoever is parsing, and it is here for
/// two reasons.
///
/// The first is a rule: a failure belongs to the package that owns the port.
/// `ActorId.parse` returns an `IdentityFailure`, and a `ShipmentGateway` whose
/// signature promises `ShipmentFailure` may not hand one of identity's back.
/// Somebody has to translate, and doing it here means it is translated once
/// rather than in every adapter that reads a courier.
///
/// The second is what that rule protects. `shipments_infrastructure` may not
/// depend on a foreign `_api` at all — section 2, and the reason is written
/// down: an adapter that reaches another feature's concepts has taken on a use
/// case's job. Without this function an adapter would have no way to rebuild
/// the `ActorId` its own contract is expressed in, and the pressure would be
/// to widen the rule. What the adapter actually needs is not identity's
/// vocabulary but shipments' answer to "is this a courier we can name?", and
/// that answer belongs here.
abstract final class CourierReference {
  /// Reads [raw] as the identifier of a courier.
  static Result<ActorId, ShipmentFailure> parse(String raw) =>
      ActorId.parse(raw).mapFailure(
        (failure) => MalformedValue(field: 'courier', reason: '$failure'),
      );

  /// Reads [raw] where a courier is optional, as on a recorded move.
  ///
  /// Absent is a success carrying `null`: the end-of-shift sweep has no actor,
  /// and a failure there would make every system-made move unreadable. Present
  /// but unreadable is still a failure — an audit trail that quietly drops who
  /// did something is worse than one that admits it could not be read.
  static Result<ActorId?, ShipmentFailure> parseOptional(String? raw) =>
      raw == null ? const Success(null) : parse(raw);
}
