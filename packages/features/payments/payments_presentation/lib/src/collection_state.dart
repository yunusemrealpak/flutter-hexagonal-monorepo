import 'package:payments_api/payments_api.dart';

/// What the collection screen can be showing.
///
/// Sealed and hand-written, in a package with no code generation at all. Six
/// cases rather than one class with `isLoading`, `amount` and `failure` on it:
/// the flat shape lets a widget be handed a state that owes money *and* has
/// already collected it, and the day two of those are set at once nobody can
/// say what should be on screen.
sealed class CollectionState {
  const CollectionState();
}

/// Nothing has been asked for yet.
final class CollectionIdle extends CollectionState {
  /// Creates the state.
  const CollectionIdle();
}

/// What is owed is being read.
final class CollectionLoading extends CollectionState {
  /// Creates the state.
  const CollectionLoading();
}

/// This parcel is paid for.
///
/// A state of its own rather than an amount of zero. Most parcels are prepaid,
/// so this is where the screen spends most of its life, and "nothing to
/// collect" and "collect nothing" are different sentences to put in front of a
/// courier at a door.
final class NothingOwed extends CollectionState {
  /// Creates the state.
  const NothingOwed();
}

/// Money is owed and has not been taken.
final class Owed extends CollectionState {
  /// Creates the state.
  const Owed(
    this.amount, {
    this.method = const PaymentMethod.cash(),
    this.refusal,
  });

  /// How much, as payments reported it.
  ///
  /// **Read, never typed.** The amount comes from `PaymentStatus`, so a
  /// courier cannot collect a different number from the one the operation is
  /// owed — and a screen that offered a text field would be the place that
  /// difference got in.
  final Money amount;

  /// How the courier is taking it.
  final PaymentMethod method;

  /// A collection payments refused, or `null`.
  ///
  /// Carried beside the amount rather than replacing the state. The money is
  /// still owed and the courier is still at the door; dropping to a failure
  /// state would end a visit that has not finished.
  final PaymentsFailure? refusal;

  /// Returns a copy with the given fields replaced.
  Owed copyWith({PaymentMethod? method, PaymentsFailure? refusal}) =>
      Owed(amount, method: method ?? this.method, refusal: refusal);
}

/// The money changed hands.
final class Collected extends CollectionState {
  /// Creates the state.
  const Collected(this.attempt);

  /// What was recorded.
  final PaymentAttempt attempt;
}

/// What is owed could not be read.
final class CollectionFailed extends CollectionState {
  /// Creates the state.
  const CollectionFailed(this.failure);

  /// What went wrong, in payments' own words.
  ///
  /// A `PaymentsFailure`, not a `String`. Turning it into a message is this
  /// layer's job and it happens at the widget, where the locale is known.
  final PaymentsFailure failure;
}
