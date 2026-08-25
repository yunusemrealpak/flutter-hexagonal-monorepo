import 'package:core_kernel/core_kernel.dart';

import 'identity_failure.dart';

/// Identifies one human or service account across the whole product.
///
/// Wrapping a `String` is only worth the ceremony when the wrapper stops a
/// different string being passed where this one is meant, and it does: a
/// `ShipmentId` and an `ActorId` are both strings on the wire and are never
/// interchangeable in a signature.
///
/// There is no public constructor. The only way to obtain one is [parse],
/// which returns a `Result`, so an invalid identifier cannot exist as a value
/// — validation happens once, at the edge, instead of at every use.
final class ActorId extends ValueObject<String> {
  const ActorId._(super.value);

  /// Reads an actor identifier from [raw].
  ///
  /// Surrounding whitespace is trimmed, because an identifier that came from a
  /// header or a form field routinely carries it and the trimmed and untrimmed
  /// forms are the same actor. Nothing else is normalised: identifiers are
  /// case-sensitive on the server, so lower-casing here would silently merge
  /// two accounts.
  static Result<ActorId, IdentityFailure> parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const Failed(MalformedActorId(''));
    }
    return Success(ActorId._(trimmed));
  }
}
