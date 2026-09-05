import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_outcome.freezed.dart';

/// Where one attempt to move money has got to.
///
/// Four states carrying different things, which is why this is a union and not
/// a set of nullable fields on the attempt. A pending attempt has no instant;
/// a taken one has the moment the money changed hands; a refused one has what
/// the far side said; a refunded one has both the taking and the giving back.
///
/// [PaymentRefunded] keeps `takenAt` as well as `refundedAt`. A refund is not
/// the erasure of a payment — the money was taken, and a settlement that
/// forgot the first half could not explain the second.
@freezed
sealed class PaymentOutcome with _$PaymentOutcome {
  const PaymentOutcome._();

  /// Nobody has answered yet.
  const factory PaymentOutcome.pending() = PaymentPending;

  /// The money changed hands.
  const factory PaymentOutcome.taken({required DateTime at}) = PaymentTaken;

  /// The customer, the card or the bank said no.
  const factory PaymentOutcome.refused({required String reason}) =
      PaymentRefused;

  /// It was taken and then given back.
  const factory PaymentOutcome.refunded({
    required DateTime takenAt,
    required DateTime refundedAt,
  }) = PaymentRefunded;

  /// Whether this outcome is final.
  ///
  /// A refusal is *not* settled: a card that was declined can be tried again
  /// with the same intention, and treating it as final would leave a courier
  /// unable to take the money the customer is holding out. Only money that
  /// actually moved closes an attempt.
  bool get isSettled => switch (this) {
    PaymentTaken() || PaymentRefunded() => true,
    PaymentPending() || PaymentRefused() => false,
  };
}
