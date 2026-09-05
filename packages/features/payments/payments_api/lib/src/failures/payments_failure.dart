import 'package:core_kernel/core_kernel.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'payments_failure.freezed.dart';

/// Everything that can go wrong on a payments port, or inside a collection.
///
/// Sealed, so a caller that handles the cases exhaustively keeps compiling
/// only for as long as it still handles all of them.
///
/// Note what is *not* here: there is no `duplicateCollection`. A second
/// request carrying the same idempotency key is not an error — it is the same
/// intention arriving twice, and the correct answer is the first one's result.
/// A failure case for it would make every retry look like a fault and would
/// tempt a caller to swallow it.
@freezed
sealed class PaymentsFailure extends Failure with _$PaymentsFailure {
  const PaymentsFailure._();

  /// A value object refused the input it was given.
  const factory PaymentsFailure.malformedValue({
    required String field,
    required String reason,
  }) = MalformedPaymentValue;

  /// Two amounts in different currencies were put together.
  ///
  /// Its own case rather than a malformed value, because it is the one
  /// arithmetic mistake in this feature that silently produces a plausible
  /// number. Adding 10 EUR to 10 TRY has no answer, and any code that returned
  /// 20 of something would be wrong in a way nobody notices until a
  /// settlement.
  const factory PaymentsFailure.currencyMismatch({
    required String expected,
    required String actual,
  }) = CurrencyMismatch;

  /// The customer, the card or the bank said no.
  ///
  /// Carries the reason as the far side gave it, because a courier standing at
  /// a door has to be able to say *why* — "insufficient funds" and "card
  /// expired" send them to different next steps.
  const factory PaymentsFailure.collectionRefused({required String reason}) =
      CollectionRefused;

  /// This intention has already been taken or refunded.
  const factory PaymentsFailure.alreadySettled(String key) = AlreadySettled;

  /// Nothing was ever collected against this parcel.
  const factory PaymentsFailure.noCollectionFor(String shipment) =
      NoCollectionFor;

  /// Money that was never taken cannot be given back.
  const factory PaymentsFailure.refundNotPossible({required String reason}) =
      RefundNotPossible;

  /// The cash drawer could not be reached or would not accept the amount.
  const factory PaymentsFailure.cashDrawerUnavailable({String? detail}) =
      CashDrawerUnavailable;

  /// The payments service could not be reached.
  const factory PaymentsFailure.paymentsUnavailable({String? detail}) =
      PaymentsUnavailable;

  /// The day's settlement could not be read or written.
  const factory PaymentsFailure.settlementUnavailable({String? detail}) =
      SettlementUnavailable;

  /// The day is closed and no longer accepts changes.
  const factory PaymentsFailure.settlementClosed(String settlement) =
      SettlementClosed;
}
