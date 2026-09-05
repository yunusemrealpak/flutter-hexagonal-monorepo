import 'package:core_kernel/core_kernel.dart';

import '../../entities/payment_attempt.dart';
import '../../failures/payments_failure.dart';

/// The operation's record of the money it has taken.
///
/// A driven port. It speaks in attempts, never in requests: there is no URL,
/// no header and no status code in this file, and there cannot be —
/// `payments_application`, which consumes it, may not depend on `platform/*`.
///
/// **`collect` is idempotent about *money*, not about rows**, and the
/// distinction is the whole contract. An attempt carries its key as its
/// identifier; once money has moved under that key, sending it again produces
/// no second movement and the same answer as the first time. Until money has
/// moved, the same key may be sent again to carry the intention forward — an
/// office that recorded an expected cash amount, a courier who then took it.
///
/// The two halves are what a courier actually meets. A retry in a tunnel must
/// not charge twice; a collection the operation created before the visit must
/// still be closable when the visit happens. A gateway that refused the second
/// case in the name of the first would leave every pre-recorded collection
/// open for ever.
///
/// Every implementation is held to both by the contract kit in
/// `payments_testing`, which is the only way to be sure a fake and a REST
/// adapter agree.
abstract interface class PaymentsGateway {
  /// Records [attempt]'s movement of money under its key.
  ///
  /// Returns the stored attempt untouched when money has already moved under
  /// that key, and otherwise stores what it was given.
  Future<Result<PaymentAttempt, PaymentsFailure>> collect(
    PaymentAttempt attempt,
  );

  /// Gives back what was taken under [key].
  ///
  /// Takes the raw key rather than an `IdempotencyKey`, like every driven
  /// port's identifier in this workspace: an adapter has to be able to write
  /// the signature down without the value objects of the feature it serves.
  /// Here that adapter is payments' own, so the constraint costs nothing —
  /// and applying it anyway keeps one rule instead of two.
  Future<Result<PaymentAttempt, PaymentsFailure>> refund(String key);

  /// The attempt recorded against [shipmentId], or `null` when there is none.
  ///
  /// This is what makes an intention findable. A courier whose collection
  /// timed out taps *collect* again, and the use case asks this before it
  /// mints anything — because a second key would be a second intention, and a
  /// second intention is a second charge.
  Future<Result<PaymentAttempt?, PaymentsFailure>> attemptFor(
    String shipmentId,
  );
}
