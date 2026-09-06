import 'package:flutter/foundation.dart';

/// What the badge can be showing.
@immutable
sealed class UnreadState {
  const UnreadState();
}

/// No count has arrived yet.
///
/// A case of its own rather than zero, and the difference is what a person
/// sees: zero is a claim that nothing is waiting, and this is an admission
/// that nothing is known yet. The badge draws nothing here, so an inbox with
/// three alerts in it never flashes "no alerts" on the way to saying so.
final class UnreadUnknown extends UnreadState {
  /// Creates the state.
  const UnreadUnknown();
}

/// How many alerts are waiting.
final class UnreadCount extends UnreadState {
  /// Creates the state.
  const UnreadCount(this.value);

  /// The count, as the store last reported it.
  final int value;

  /// Equality on the number, and it is load-bearing.
  ///
  /// The stream behind this re-reports the same count whenever anything in the
  /// store moves — an alert marked read on another device, a push that turned
  /// out to be a duplicate. `Bloc` drops an emission that compares equal to
  /// the one before it, so this is what keeps a badge that has not changed
  /// from rebuilding on every one of them. Safe to write by hand here because
  /// the state carries an `int` and not an entity.
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is UnreadCount && other.value == value;

  @override
  int get hashCode => value.hashCode;
}
