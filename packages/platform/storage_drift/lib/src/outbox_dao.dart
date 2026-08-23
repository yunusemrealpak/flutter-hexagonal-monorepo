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

  /// The oldest [limit] entries, oldest first.
  Future<List<OutboxEntry>> pending({int limit = 50}) {
    return (select(outboxEntries)
          ..orderBy([(row) => OrderingTerm.asc(row.createdAt)])
          ..limit(limit))
        .get();
  }

  /// Records that delivery of [id] was attempted at [attemptedAt], and
  /// increments the attempt count.
  ///
  /// Written as one statement rather than read-modify-write on purpose: two
  /// isolates draining the same outbox would otherwise both read the same
  /// count and both write the same increment, and the backoff schedule that
  /// depends on it would stall.
  Future<void> recordAttempt(String id, DateTime attemptedAt) {
    return customUpdate(
      'UPDATE outbox_entries SET attempt_count = attempt_count + 1, '
      'last_attempt_at = ? WHERE id = ?',
      variables: [Variable.withDateTime(attemptedAt), Variable.withString(id)],
      updates: {outboxEntries},
    );
  }

  /// Removes [id] once the server has accepted the work.
  Future<void> drop(String id) =>
      (delete(outboxEntries)..where((row) => row.id.equals(id))).go();
}
