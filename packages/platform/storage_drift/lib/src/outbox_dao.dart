import 'package:drift/drift.dart';
import 'outbox_entries.dart';
import 'peyk_database.dart';

part 'outbox_dao.g.dart';

/// Every query the outbox table answers.
///
/// The `sync` feature's `OutboxStore` port is implemented on top of this in
/// phase 5. The split matters: the port speaks in `sync`'s vocabulary and
/// returns `Result`, while this object speaks SQL and is allowed to throw,
/// because it is below the boundary rather than on it.
@DriftAccessor(tables: [OutboxEntries])
class OutboxDao extends DatabaseAccessor<PeykDatabase> with _$OutboxDaoMixin {
  /// Reads and writes through the attached database.
  OutboxDao(super.attachedDatabase);

  /// Queues [entry], or replaces the one that already carries its id.
  ///
  /// Replacing rather than failing is what makes queueing idempotent: a
  /// feature that retries after a crash mid-write ends up with one entry, not
  /// two.
  Future<void> enqueue(OutboxEntry entry) =>
      into(outboxEntries).insertOnConflictUpdate(entry);

  /// The oldest [limit] entries that are not blocked, oldest first.
  ///
  /// The ordering is part of the port's contract rather than a convenience:
  /// work queued earlier describes a world the later work assumes, and a
  /// payment drained before the delivery it belongs to reaches a server that
  /// has not been told about the shipment. The tie-break on `id` matters for
  /// the same reason — two rows written in the same millisecond have to come
  /// back in the same order on every read, or a contract kit passes against a
  /// map and fails against a table.
  ///
  /// Blocked rows are excluded here rather than deleted. That is what lets one
  /// rejected entry wait for a person while everything behind it keeps
  /// draining.
  Future<List<OutboxEntry>> pending({int limit = 50}) {
    return (select(outboxEntries)
          ..where((row) => row.blockedReason.isNull())
          ..orderBy([
            (row) => OrderingTerm.asc(row.createdAt),
            (row) => OrderingTerm.asc(row.id),
          ])
          ..limit(limit))
        .get();
  }

  /// Every entry a person has to look at, oldest first.
  Future<List<OutboxEntry>> blocked() {
    return (select(outboxEntries)
          ..where((row) => row.blockedReason.isNotNull())
          ..orderBy([
            (row) => OrderingTerm.asc(row.createdAt),
            (row) => OrderingTerm.asc(row.id),
          ]))
        .get();
  }

  /// One entry, or `null` when nothing is stored under [id].
  Future<OutboxEntry?> byId(String id) {
    return (select(
      outboxEntries,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
  }

  /// Records that delivery of [id] was attempted at [attemptedAt], increments
  /// the attempt count, and schedules the next try for [nextAttemptAt].
  ///
  /// Written as one statement rather than read-modify-write on purpose: two
  /// isolates draining the same outbox would otherwise both read the same
  /// count and both write the same increment, and the backoff schedule that
  /// depends on it would stall.
  ///
  /// **[nextAttemptAt] travels with the increment**, and leaving it out is why
  /// this statement had no caller for three phases. A drain that recorded an
  /// attempt here and wrote the backoff separately would need two statements
  /// to express one decision — so it wrote the whole row instead, through the
  /// upsert, which is exactly the read-modify-write this exists to prevent.
  ///
  /// The three columns it does not touch are the point of the statement. An
  /// upsert writes every column from an in-memory copy read at the top of the
  /// drain; this writes the three that a failed attempt changes and leaves the
  /// payload, the policy and the blocked reason as the table has them.
  Future<void> recordAttempt(
    String id,
    DateTime attemptedAt,
    DateTime nextAttemptAt,
  ) {
    return customUpdate(
      'UPDATE outbox_entries SET attempt_count = attempt_count + 1, '
      'last_attempt_at = ?, next_attempt_at = ? WHERE id = ?',
      variables: [
        Variable.withDateTime(attemptedAt),
        Variable.withDateTime(nextAttemptAt),
        Variable.withString(id),
      ],
      updates: {outboxEntries},
    );
  }

  /// Removes [id] once the server has accepted the work.
  Future<void> drop(String id) =>
      (delete(outboxEntries)..where((row) => row.id.equals(id))).go();
}
