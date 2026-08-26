import 'package:core_kernel/core_kernel.dart';

import 'payment_attempt.dart';
import 'payments_failure.dart';

/// The operation's record of the money it has taken.
///
/// A driven port. It speaks in attempts, never in requests: there is no URL,
/// no header and no status code in this file, and there cannot be —
/// `payments_application`, which consumes it, may not depend on `platform/*`.
///
/// **`collect` is idempotent, and that is a promise the contract makes rather
/// than a hope about the server.** An attempt carries its key as its
/// identifier; sending the same attempt twice must produce one movement of
/// money and the same answer both times. Every implementation is held to that
/// by the contract kit in `payments_testing`, which is the only way to be sure
/// a fake and a REST adapter agree about the case a courier meets in a tunnel.
abstract interface class PaymentsGateway {
  /// Records [attempt], or returns what the first copy of it produced.
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
