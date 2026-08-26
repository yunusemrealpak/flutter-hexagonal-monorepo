import 'package:core_kernel/core_kernel.dart';

import 'payments_failure.dart';

/// Names one intention to move money, for as long as anybody retries it.
///
/// **This is the most important type in the feature.** A courier taps
/// *collect*, the request times out, and the phone has no way to know whether
/// the money was taken. Without a key, the retry is a second charge; with one,
/// the far side recognises the second request as the same intention and
/// answers with the first one's result.
///
/// The key is minted once per *intention*, not once per call — from the
/// `IdGenerator` port, in the use case, and then carried on the attempt. That
/// is why `PaymentAttempt` uses this type as its identifier rather than
/// inventing one beside it: two attempts with the same key are not two
/// attempts, and a type system that let you build them separately would make
/// the double charge expressible.
///
/// It is deliberately opaque. Deriving it from the shipment and the amount
/// would look clever and would collide the day a customer legitimately pays
/// twice for the same parcel — a second delivery attempt after a return.
final class IdempotencyKey extends ValueObject<String> {
  const IdempotencyKey._(super.value);

  /// Reads a key from [raw].
  static Result<IdempotencyKey, PaymentsFailure> parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const Failed(
        MalformedPaymentValue(field: 'idempotencyKey', reason: 'is empty'),
      );
    }
    return Success(IdempotencyKey._(trimmed));
  }
}
