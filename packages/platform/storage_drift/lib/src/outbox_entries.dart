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

  @override
  Set<Column<Object>> get primaryKey => {id};
}
