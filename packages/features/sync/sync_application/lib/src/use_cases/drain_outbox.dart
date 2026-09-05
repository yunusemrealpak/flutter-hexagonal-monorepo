import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:sync_api/sync_api.dart';

import 'read_sync_status.dart';

/// Attempts every due entry, oldest first, and decides what each outcome
/// means.
///
/// This is the one place in the workspace where a retry policy lives, and it
/// is worth reading as a list of decisions rather than as a loop:
///
/// **Offline stops the drain without counting an attempt.** A device in a
/// tunnel would otherwise burn its whole attempt budget in a single pass —
/// eight failures in eight milliseconds — and block a shift's work for manual
/// review because of a lift. The request never left, so it was not an attempt.
///
/// **A store failure stops the drain and is reported.** Everything else here
/// is "not yet"; a store that cannot be read is a queue that cannot be trusted
/// to remember, and continuing to write into one is how work disappears
/// quietly.
///
/// **A permanent failure blocks one entry and the rest keep going.** Retrying
/// a 422 produces the same 422 until a person looks, and leaving it at the
/// head of the queue would stop everything behind it.
///
/// **A conflict is the entry's `ConflictPolicy`'s decision, not this class's.**
/// The server's new position is saved either way, because the device has now
/// heard it and pretending otherwise would make the next envelope conflict
/// against a position it already knows is stale.
///
/// The jitter for each backoff is drawn once, here, from the `RandomSource`
/// port, and the resulting instant is written onto the entry. Rule A2, and the
/// reason `RetrySchedule` takes the draw as an argument instead of making it.
///
/// **What it writes is as deliberate as what it decides.** A drain reads a
/// batch and then spends a network round trip per entry, so every value it
/// holds is a snapshot. `recordAttempt`, `block` and `accepted` each change
/// the fields their own outcome changes; nothing here writes a whole entry
/// from the copy it read.
///
/// **Whether to give up is decided from the count the store wrote**, not from
/// the one this class read. That was the last place the snapshot leaked into a
/// decision, and it was correct exactly while one drain ran at a time: two
/// drains both holding `3` would each decide `4` was within budget while the
/// store had reached `5`. `platform/background_tasks` is what makes the second
/// drain real, so `recordAttempt` now answers its count and this spends the
/// budget against that.
///
/// The backoff is still computed from the local count, and that asymmetry is
/// deliberate: the length of a wait is a heuristic and being one step out
/// costs a few seconds, while giving up is irreversible and costs a person a
/// review queue entry that should not be there.
final class DrainOutbox
    implements UseCase<(), Result<SyncStatus, SyncFailure>> {
  /// Creates the use case.
  const DrainOutbox({
    required this._store,
    required this._transport,
    required this._skew,
    required this._clock,
    required this._random,
    required this._network,
    required this._logger,
    required this._status,
    this.schedule = RetrySchedule.standard,
    this.batchSize = 50,
  });

  final OutboxStore _store;
  final CommandTransportPort _transport;
  final ClockSkewPort _skew;
  final Clock _clock;
  final RandomSource _random;
  final NetworkStatus _network;
  final Logger _logger;
  final ReadSyncStatus _status;

  /// How long to wait between attempts, and when to give up.
  final RetrySchedule schedule;

  /// How many entries one drain works through.
  ///
  /// A device coming back from a day offline should not hold one database
  /// transaction open across five hundred requests. What is left over is
  /// reported as `SyncStatus.draining`, which is this feature's way of saying
  /// "call me again".
  final int batchSize;

  @override
  Future<Result<SyncStatus, SyncFailure>> call(() input) async {
    if (_network.current == NetworkCondition.offline) {
      // Not a failure. Being offline is the ordinary state of an offline-first
      // product, and reporting it as an error would put a red banner on a
      // courier's screen for every basement they walk into.
      return _status(());
    }

    final List<OutboxEntry> entries;
    switch (await _store.pending(limit: batchSize)) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        entries = value;
    }
    if (entries.isEmpty) return _status(());

    SyncCursor cursor;
    switch (await _store.cursor()) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        cursor = value;
    }

    // A drain proceeds without knowing the skew rather than refusing to run.
    // The correction improves ordering between devices; not sending the work
    // at all improves nothing.
    final skew = (await _skew.skew()).fold(
      (value) => value,
      (failure) {
        _logger.debug(
          'draining without a clock-skew correction',
          context: {'failure': '$failure'},
        );
        return Duration.zero;
      },
    );

    final now = _clock.now();
    for (final entry in entries) {
      if (!entry.isDueAt(now)) continue;

      final sent = await _transport.send(
        entry.envelopeFor(cursor: cursor, clockSkew: skew),
      );

      switch (sent) {
        case Success(value: final position):
          // One call, because it is one fact. Dropping the row and saving the
          // cursor as two writes leaves a window in which the device has
          // forgotten work the server has and still believes the server is
          // where it was — so the next envelope goes out from a position it
          // has already been told is stale.
          final done = await _store.accepted(entry.id, position);
          if (done case Failed(:final failure)) return Failed(failure);

          cursor = position;

        case Failed(failure: SyncOffline()):
          // The connection went away mid-drain. Stop, and leave every entry
          // exactly as it was — including this one, whose attempt never
          // reached anything.
          _logger.info('drain stopped: the connection went away');
          return _status(());

        case Failed(failure: final SyncConflict conflict):
          cursor = SyncCursor(conflict.cursor);
          final saved = await _store.saveCursor(cursor);
          if (saved case Failed(:final failure)) return Failed(failure);

          final resolved = await _resolveConflict(entry, conflict, now);
          if (resolved case Failed(:final failure)) return Failed(failure);

        case Failed(:final failure):
          final recorded = failure.isTransient
              ? await _recordAttempt(entry, failure, now)
              : await _block(entry, 'rejected: $failure');
          if (recorded case Failed(:final failure)) return Failed(failure);
      }
    }

    return _status(());
  }

  /// Applies what the feature chose when it queued this work.
  Future<Result<void, SyncFailure>> _resolveConflict(
    OutboxEntry entry,
    SyncConflict conflict,
    DateTime now,
  ) => switch (entry.policy) {
    // The device's version stands. Nothing is dropped and nothing is blocked;
    // the entry goes back into the schedule and the next envelope carries the
    // server's new cursor, which makes it a different request rather than the
    // same one repeated.
    LastWriteWins() => _recordAttempt(entry, conflict, now),

    // The server's version stands, so this work is finished — not failed.
    // Blocking it would put a decision in front of a person who has nothing
    // left to decide.
    ServerWins() => _store.drop(entry.id),

    ManualReview() => _block(entry, 'conflict: ${conflict.detail}'),
  };

  /// Counts a failed attempt and schedules the next one, or gives up.
  ///
  /// The order is *record, then decide*, and it is the other way round from
  /// how it reads. Only the store knows how many attempts this entry has had
  /// once a second drain exists, and the only way to ask is to write. The
  /// intermediate state that leaves — an entry scheduled for a next attempt it
  /// will never get — lasts one statement and is harmless either way: a
  /// blocked entry is never due.
  Future<Result<void, SyncFailure>> _recordAttempt(
    OutboxEntry entry,
    SyncFailure failure,
    DateTime now,
  ) async {
    // From the local count, on purpose. The backoff has to be chosen before
    // the write that reveals the real count, and a wait one step out costs a
    // few seconds — where giving up one attempt early costs a person a review
    // queue entry that should not be there.
    final backoff = schedule.delayAfter(
      entry.attempts + 1,
      jitter: _random.nextDouble(),
    );

    // Not `put`. The entry in hand was read at the top of this pass and one
    // network round trip has happened since, so writing it back whole would
    // undo anything that changed in between — including a person blocking it
    // from the review screen, which would put work somebody deliberately
    // stopped back into the queue with no reason on it.
    final counted = await _store.recordAttempt(
      entry.id,
      at: now,
      nextAttemptAt: now.add(backoff),
    );

    final int attempts;
    switch (counted) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        attempts = value;
    }

    if (!schedule.allowsAnotherAttempt(attempts)) {
      return _block(entry, 'gave up after $attempts attempts');
    }

    _logger.debug(
      'retrying queued work later',
      context: {
        'entry': entry.id.value,
        'attempts': attempts,
        'in': '${backoff.inMilliseconds}ms',
        'failure': '$failure',
      },
    );
    return const Success(null);
  }

  /// Takes an entry out of the drain and leaves it for a person.
  Future<Result<void, SyncFailure>> _block(OutboxEntry entry, String reason) {
    _logger.warning(
      'queued work needs a person',
      context: {'entry': entry.id.value, 'type': entry.type, 'reason': reason},
    );
    // An intent rather than `put(entry.blocked(reason))`. The entry in hand is
    // the snapshot again: writing it whole would roll back an attempt a second
    // drain counted since, and the store keeps whichever reason arrived first.
    return _store.block(entry.id, reason);
  }
}
