import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_method.freezed.dart';

/// How the money changed hands.
///
/// A closed union rather than an enum, because the cases carry different
/// things and are settled in different places: cash goes into a drawer the
/// courier is accountable for, a card goes to an acquirer, a transfer is
/// somebody else's reference that has to be quoted back.
///
/// [Cash] is the case the rest of this feature is shaped around. It is the one
/// where a person is holding money at a door, which is why it is the one that
/// needs a drawer, a receipt and a daily settlement — and the one where a
/// retry that charges twice is a real loss rather than a reversible one.
@freezed
sealed class PaymentMethod with _$PaymentMethod {
  const PaymentMethod._();

  /// Notes and coins, at the door.
  const factory PaymentMethod.cash() = Cash;

  /// A card, on the courier's terminal.
  ///
  /// [last4] and nothing else. A payments feature that held a full number
  /// would be a payments feature inside the compliance scope of everything
  /// that could read it, and the last four digits are what a customer
  /// recognises on a receipt.
  const factory PaymentMethod.card({required String last4}) = Card;

  /// Money that arrived before the courier did.
  const factory PaymentMethod.transfer({required String reference}) = Transfer;

  /// Whether this method puts money in the courier's hands.
  ///
  /// The question the cash drawer and the daily settlement both ask.
  /// Behaviour on the union rather than a `switch` in each of them, because
  /// two copies would disagree the first time a case was added.
  bool get isCash => this is Cash;
}
