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
        case Success(value: final accepted):
          final removed = await _store.drop(entry.id);
          if (removed case Failed(:final failure)) return Failed(failure);

          cursor = accepted;
          final saved = await _store.saveCursor(cursor);
          if (saved case Failed(:final failure)) return Failed(failure);

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
  Future<Result<void, SyncFailure>> _recordAttempt(
    OutboxEntry entry,
    SyncFailure failure,
    DateTime now,
  ) {
    if (!schedule.allowsAnotherAttempt(entry.attempts + 1)) {
      return _block(entry, 'gave up after ${entry.attempts + 1} attempts');
    }

    final backoff = schedule.delayAfter(
      entry.attempts + 1,
      jitter: _random.nextDouble(),
    );
    _logger.debug(
      'retrying queued work later',
      context: {
        'entry': entry.id.value,
        'attempts': entry.attempts + 1,
        'in': '${backoff.inMilliseconds}ms',
        'failure': '$failure',
      },
    );
    return _store.put(entry.attempted(at: now, backoff: backoff));
  }

  /// Takes an entry out of the drain and leaves it for a person.
  Future<Result<void, SyncFailure>> _block(OutboxEntry entry, String reason) {
    _logger.warning(
      'queued work needs a person',
      context: {'entry': entry.id.value, 'type': entry.type, 'reason': reason},
    );
    return _store.put(entry.blocked(reason));
  }
}
