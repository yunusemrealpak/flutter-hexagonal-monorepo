import 'package:flutter/foundation.dart';
import 'package:payments_api/payments_api.dart';

/// What the collection screen can be showing.
///
/// Sealed and hand-written, in a package with no code generation at all. Six
/// cases rather than one class with `isLoading`, `amount` and `failure` on it:
/// the flat shape lets a widget be handed a state that owes money *and* has
/// already collected it, and the day two of those are set at once nobody can
/// say what should be on screen.
/// **Every case carries value equality, and that is load-bearing now.** A
/// `Bloc` compares the state it is about to emit against the one it holds and
/// drops the emission when they are equal, which is what makes `BlocSelector`
/// worth using and what stops a rebuild nobody asked for. Under
/// `ChangeNotifier` these classes needed no `==` at all, because
/// `notifyListeners` never compared anything.
///
/// **A state must never delegate its equality to an entity's.** `Entity` in
/// `core_kernel` compares by identifier — deliberately, so that "is this the
/// same courier?" and "has this courier changed?" stay separate questions —
/// so a state that wrote `attempt == other.attempt` would call an updated
/// record equal to the one it replaced, the emission would be dropped, and the
/// screen would keep drawing the old value. The domain is immutable and
/// evolves through `copyWith`, so a changed entity is always a different
/// instance: [Collected] compares its attempt with `identical`, which is
/// exactly the question being asked.
@immutable
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

  /// Plain value equality: all three fields already have it.
  ///
  /// `Money` hand-writes it, and `PaymentMethod` and `PaymentsFailure` are
  /// `freezed` unions, which generate it. Nothing here is an entity, so
  /// nothing here needs [identical].
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Owed &&
          other.amount == amount &&
          other.method == method &&
          other.refusal == refusal;

  @override
  int get hashCode => Object.hash(amount, method, refusal);
}

/// The money changed hands.
final class Collected extends CollectionState {
  /// Creates the state.
  const Collected(this.attempt);

  /// What was recorded.
  final PaymentAttempt attempt;

  /// Identity, not equality, and the difference matters.
  ///
  /// `PaymentAttempt` is an `Entity<IdempotencyKey>`, so `==` on it answers
  /// "the same attempt", not "the same contents". Comparing that way would let
  /// a settled attempt replace an accepted one with the same key and be
  /// dropped as a duplicate emission. [identical] answers the question this
  /// state is actually asking.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Collected && identical(other.attempt, attempt);

  @override
  int get hashCode => identityHashCode(attempt);
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

  /// Value equality: `PaymentsFailure` is a `freezed` union and has it.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollectionFailed && other.failure == failure;

  @override
  int get hashCode => failure.hashCode;
}
