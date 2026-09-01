import 'package:drift/drift.dart';

/// Durable work that has not reached the server yet.
///
/// This table is the storage half of the `sync` feature's `OutboxStore` port,
/// which arrives in phase 5. It is created here, in schema version 2, because
/// the schema belongs to the database and the database belongs to this
/// package: a table that appeared later, from a feature package, would make
/// the migration history depend on which features an application happens to
/// include.
///
/// Nothing here knows what a shipment or a payment is. [feature] and
/// [operation] are opaque strings, and [payload] is whatever the feature's own
/// adapter serialised. That is what lets `sync` carry every feature's writes
/// while depending on none of them — scenario 3 of the architecture.
///
/// ## `outbox_drain`
///
/// `pending()` asks for `blocked_reason IS NULL ORDER BY created_at, id` on
/// every drain, and `blocked()` asks the same question inverted. Without an
/// index sqlite scans the whole table and sorts the result into a temporary
/// B-tree — every time, for a table whose whole purpose is to grow long on a
/// device that has been offline.
///
/// The column order is what makes one index serve both callers.
/// `blocked_reason` first turns either filter into a range rather than a
/// predicate applied per row; `created_at` and `id` after it are the ordering,
/// so sqlite reads the rows out already sorted and the `LIMIT` stops it early
/// instead of after it has sorted everything.
///
/// Not a partial index (`WHERE blocked_reason IS NULL`). That would be smaller
/// and would serve `pending()` only, leaving `blocked()` — the screen a person
/// opens when work is stuck — on a scan.
@TableIndex(
  name: 'outbox_drain',
  columns: {#blockedReason, #createdAt, #id},
)
@DataClassName('OutboxEntry')
class OutboxEntries extends Table {
  /// The identifier the feature generated for this piece of work.
  ///
  /// Supplied by the `IdGenerator` port, so it is stable across retries and
  /// unique across devices — an entry created offline on one phone has to stay
  /// distinguishable from one created on another.
  TextColumn get id => text()();

  /// Which feature the work belongs to, as an opaque string.
  TextColumn get feature => text()();

  /// What the work is, as an opaque string the owning feature understands.
  TextColumn get operation => text()();

  /// The serialised request body, encoded by the feature that queued it.
  TextColumn get payload => text()();

  /// When the entry was queued, in UTC.
  DateTimeColumn get createdAt => dateTime()();

  /// How many times delivery has been attempted.
  ///
  /// The backoff schedule is `sync`'s business; the count is persisted here
  /// because a restart must not reset it.
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();

  /// When delivery was last attempted, or `null` if it never has been.
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();

  /// What the owning feature wants done if the server has moved on, as an
  /// opaque string.
  ///
  /// Added in schema version 4, with a default, so that rows queued by an
  /// older release keep draining instead of arriving with no policy at all.
  /// The default names the option that cannot lose the device's work; a
  /// migration that defaulted to "the server wins" would silently discard
  /// whatever a courier did before the upgrade.
  TextColumn get conflictPolicy =>
      text().withDefault(const Constant('lastWriteWins'))();

  /// The earliest instant a further attempt should be made, or `null` while
  /// the entry has never failed.
  ///
  /// Persisted rather than derived. The backoff is jittered, so recomputing it
  /// on read would answer differently every time — and a device killed
  /// mid-backoff would come back and retry everything at once.
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();

  /// Why a person has to look at this row, or `null` while it is still
  /// draining normally.
  ///
  /// A blocked row stays in the table. Deleting it would destroy the record of
  /// a delivery or a payment the operation still has to reconcile; leaving it
  /// in the pending query would stop everything behind it.
  TextColumn get blockedReason => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
