import 'package:freezed_annotation/freezed_annotation.dart';

part 'conflict_policy.freezed.dart';

/// What to do when the server has already moved past the position this device
/// wrote against.
///
/// Chosen by the feature that queued the work, at the moment it queued it, and
/// carried on the entry from then on. That is the placement worth noticing:
/// the policy is a *domain* decision — whether a courier's offline
/// proof-of-delivery outranks whatever the office typed in the meantime is a
/// question about the business, not about HTTP — and sync could not answer it
/// even if it wanted to, because it never learns what the command contains.
///
/// A closed union rather than an enum, so that a case can carry what it needs:
/// [ManualReview] names a queue, and a fourth policy with a merge function
/// would carry that.
@freezed
sealed class ConflictPolicy with _$ConflictPolicy {
  const ConflictPolicy._();

  /// The device's write is re-sent against the server's new position.
  ///
  /// For work where the newest fact is the true one and no information is
  /// destroyed by overwriting: a courier's current location, a route the
  /// device recalculated.
  const factory ConflictPolicy.lastWriteWins() = LastWriteWins;

  /// The device's write is dropped and the entry is removed.
  ///
  /// For work that has already been superseded by definition — a status the
  /// office has since corrected. The entry is *dropped*, not blocked: keeping
  /// it would put a decision in front of a person who has nothing to decide.
  const factory ConflictPolicy.serverWins() = ServerWins;

  /// The entry is blocked and waits for a human.
  ///
  /// For work that cannot be reconciled automatically without losing money or
  /// evidence. A cash collection is the example the product actually has: two
  /// records of the same payment are either a double charge or a lost one, and
  /// no rule this package can hold knows which.
  const factory ConflictPolicy.manualReview() = ManualReview;

  /// Whether an entry under this policy should be tried again after a
  /// conflict.
  ///
  /// Only [LastWriteWins] says yes. The retry then goes out against the
  /// cursor the server reported, which is what makes it a different request
  /// rather than the same one repeated.
  bool get retriesAfterConflict => this is LastWriteWins;
}
