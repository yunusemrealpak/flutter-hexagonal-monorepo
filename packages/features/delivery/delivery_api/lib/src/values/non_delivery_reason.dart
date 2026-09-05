import 'package:freezed_annotation/freezed_annotation.dart';

part 'non_delivery_reason.freezed.dart';

/// Why a visit did not end in a hand-over.
///
/// **On the success side of a `Result`, not in `DeliveryFailure`.** A courier
/// who found nobody home did their job: they drove there, they knocked, and
/// the operation now knows something it is paid to know. Modelling that as a
/// failure would put it in the same shape as "the proof store is locked", and
/// a screen could not tell a person which of the two had happened — nor could
/// a report count the first without counting the second.
///
/// A closed union rather than an enum, because the cases are not
/// interchangeable labels: a reschedule carries a date, damage carries a note
/// that somebody will read, and an address that does not exist carries what
/// was actually found there. An enum would push all three onto the attempt as
/// nullable fields that mean something in one case each.
@freezed
sealed class NonDeliveryReason with _$NonDeliveryReason {
  const NonDeliveryReason._();

  /// Nobody was there.
  const factory NonDeliveryReason.recipientAbsent() = RecipientAbsent;

  /// The address could not be found, or does not exist.
  const factory NonDeliveryReason.addressNotFound({String? found}) =
      AddressNotFound;

  /// Somebody was there and would not take it.
  const factory NonDeliveryReason.refusedByRecipient({String? note}) =
      RefusedByRecipient;

  /// The parcel arrived damaged and was not handed over.
  ///
  /// The note is required here and optional elsewhere. This is the case that
  /// becomes a claim against a carrier, and "damaged" with nothing after it is
  /// not something anybody can act on months later.
  const factory NonDeliveryReason.damagedInTransit({required String note}) =
      DamagedInTransit;

  /// The courier could not get to the door — a closed site, a locked gate.
  const factory NonDeliveryReason.accessDenied({String? note}) = AccessDenied;

  /// The recipient asked for another day.
  const factory NonDeliveryReason.rescheduled({
    required DateTime requestedFor,
  }) = Rescheduled;

  /// Whether this reason is worth sending a courier back for.
  ///
  /// Behaviour on the union rather than a `switch` in whoever asks. Both the
  /// courier's screen and the dispatcher's board want the answer, and two
  /// copies of it would disagree the first time a case was added.
  bool get isRetryable => switch (this) {
    RecipientAbsent() || AccessDenied() || Rescheduled() => true,
    AddressNotFound() || RefusedByRecipient() || DamagedInTransit() => false,
  };
}
