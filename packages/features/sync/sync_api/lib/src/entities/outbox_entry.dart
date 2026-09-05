import 'package:core_kernel/core_kernel.dart';

import '../values/conflict_policy.dart';
import '../values/outbox_entry_id.dart';
import '../values/sync_command.dart';
import '../values/sync_cursor.dart';
import '../values/sync_envelope.dart';

/// One piece of work waiting to reach the server, and everything the queue
/// knows about how it has gone so far.
///
/// An `Entity`: equality is by [id], because an entry that has been attempted
/// three times is still the same entry. That matters more here than anywhere
/// else in the workspace — the identifier is also the idempotency handle the
/// server recognises, so "same entry" and "same piece of work" have to be the
/// same statement.
///
/// The entry holds [type] and [payload] as opaque strings rather than holding
/// the [SyncCommand] it came from. A command is a live object belonging to a
/// feature; an entry is a row that has to survive the process that made it.
/// Keeping the object would mean an outbox that only works until the app is
/// killed, which is the one thing an outbox exists to survive.
///
/// **Where the randomness is not.** [nextAttemptAt] is stored, not computed on
/// read. A due-time that were recomputed from a jittered schedule every time
/// somebody asked would give a different answer each call, and an entry would
/// flicker in and out of being due. The use case that records an attempt draws
/// the jitter once, from the `RandomSource` port, and writes the resulting
/// instant down.
final class OutboxEntry extends Entity<OutboxEntryId> {
  /// Rebuilds an entry from what was stored.
  ///
  /// Used by adapters in `sync_infrastructure`. New work comes from
  /// [OutboxEntry.queued], which is the only entry point that starts the
  /// attempt count at zero.
  const OutboxEntry({
    required super.id,
    required this.type,
    required this.payload,
    required this.policy,
    required this.queuedAt,
    this.attempts = 0,
    this.lastAttemptAt,
    this.nextAttemptAt,
    this.blockedReason,
  });

  /// Queues [command] as new work.
  ///
  /// [at] comes from the `Clock` port and [id] from `IdGenerator`; neither is
  /// produced here, which is rule A1 and A3 at the place they are easiest to
  /// break.
  factory OutboxEntry.queued({
    required OutboxEntryId id,
    required SyncCommand command,
    required ConflictPolicy policy,
    required DateTime at,
  }) => OutboxEntry(
    id: id,
    type: command.type,
    payload: command.payload,
    policy: policy,
    queuedAt: at,
  );

  /// The routing key the composition root maps to a transport handler.
  final String type;

  /// The command's body, exactly as the feature serialised it.
  final String payload;

  /// What this feature wants done if the server has moved on.
  final ConflictPolicy policy;

  /// When the work was queued, corrected for clock skew if it was known.
  final DateTime queuedAt;

  /// How many times delivery has been attempted.
  final int attempts;

  /// When delivery was last attempted, or `null` if it never has been.
  final DateTime? lastAttemptAt;

  /// The earliest instant a further attempt should be made.
  ///
  /// `null` before the first failure: work that has just been queued is due
  /// immediately.
  final DateTime? nextAttemptAt;

  /// Why a person has to look at this entry, or `null` while it is still
  /// draining normally.
  final String? blockedReason;

  /// Whether this entry is out of the queue's hands.
  ///
  /// A blocked entry is skipped by the drain rather than removed. Removing it
  /// would destroy the evidence of a delivery or a payment that the operation
  /// still has to reconcile; skipping it lets everything behind it keep
  /// moving, which is the failure mode a naive queue gets wrong — one bad
  /// entry at the head and the shift's work never lands.
  bool get isBlocked => blockedReason != null;

  /// Whether an attempt should be made at [now].
  ///
  /// A blocked entry is never due. An entry that has never been attempted
  /// always is.
  bool isDueAt(DateTime now) {
    if (isBlocked) return false;
    final next = nextAttemptAt;
    return next == null || !now.isBefore(next);
  }

  /// Records a failed attempt, with the wait the schedule chose.
  ///
  /// The backoff arrives as a `Duration` rather than being derived here. The
  /// derivation needs a jitter draw, which needs the `RandomSource` port,
  /// which an entity in an `_api` package neither has nor should have.
  OutboxEntry attempted({required DateTime at, required Duration backoff}) =>
      _copyWith(
        attempts: attempts + 1,
        lastAttemptAt: at,
        nextAttemptAt: at.add(backoff),
      );

  /// Takes this entry out of the drain and marks it for a person.
  ///
  /// Called on a permanent failure, on a conflict whose policy is
  /// `manualReview`, and when the schedule's attempt limit runs out. Blocking
  /// an entry that is already blocked keeps the first reason: the first
  /// explanation is the one that describes what actually happened, and the
  /// later ones are consequences of it.
  OutboxEntry blocked(String reason) =>
      isBlocked ? this : _copyWith(blockedReason: reason);

  /// Puts this entry back into the drain after a person resolved it.
  OutboxEntry unblocked() => OutboxEntry(
    id: id,
    type: type,
    payload: payload,
    policy: policy,
    queuedAt: queuedAt,
    attempts: attempts,
    lastAttemptAt: lastAttemptAt,
  );

  /// Builds what the transport is handed for this attempt.
  ///
  /// The envelope is a projection, not a stored thing: it exists for the
  /// length of one call and carries the two facts the transport needs that the
  /// entry does not hold — where this device thinks the server is, and how far
  /// its own clock is off.
  ///
  /// [clockSkew] is added to [queuedAt] rather than to `now`. The question the
  /// server has to answer is when the work happened in *its* frame of
  /// reference, and a device whose clock is an hour slow queued the work an
  /// hour later than it says.
  SyncEnvelope envelopeFor({
    required SyncCursor cursor,
    Duration clockSkew = Duration.zero,
  }) => SyncEnvelope(
    id: id,
    type: type,
    payload: payload,
    policy: policy,
    queuedAt: queuedAt.add(clockSkew),
    attempt: attempts + 1,
    cursor: cursor,
  );

  OutboxEntry _copyWith({
    int? attempts,
    DateTime? lastAttemptAt,
    DateTime? nextAttemptAt,
    String? blockedReason,
  }) => OutboxEntry(
    id: id,
    type: type,
    payload: payload,
    policy: policy,
    queuedAt: queuedAt,
    attempts: attempts ?? this.attempts,
    lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
    nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
    blockedReason: blockedReason ?? this.blockedReason,
  );

  @override
  String toString() =>
      'OutboxEntry(${id.value}, $type, attempts: $attempts'
      '${isBlocked ? ', blocked: $blockedReason' : ''})';
}
