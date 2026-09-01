import 'package:drift/drift.dart';
import 'key_value_dao.dart';
import 'key_value_entries.dart';
import 'outbox_dao.dart';
import 'outbox_entries.dart';

part 'peyk_database.g.dart';

/// The SQLite database every Peyk application ships with.
///
/// One database, owned by this package, rather than one per feature. A feature
/// that opened its own file would make cross-feature reads impossible to do in
/// a single transaction, and would multiply the number of migration histories
/// a release has to get right. The tables are declared here; what a feature
/// does with them stays behind that feature's own port.
///
/// The [QueryExecutor] is a constructor argument and not something this class
/// chooses. That is what keeps the package pure Dart: an application passes a
/// file-backed executor, a test passes an in-memory one, and neither decision
/// is baked into the schema.
///
/// ## The migration history is the interesting part
///
/// Three versions, chosen so that each one demonstrates a different class of
/// change and so that `test/migration_test.dart` has something worth proving:
///
/// | Version | Change | Cost |
/// |---|---|---|
/// | 1 | `key_value_entries` as `(key, value, updated_at)` | — |
/// | 2 | `outbox_entries` added | new table, no existing data touched |
/// | 3 | `namespace` added to `key_value_entries`, and joined to
///     its primary key | full table rebuild |
/// | 4 | three columns appended to `outbox_entries` | in place, no rebuild |
/// | 5 | `outbox_drain` index on `outbox_entries` | one pass over the
///     rows already there |
///
/// Version 3 is the one that can lose data. A column with a default can be
/// appended in place; a *primary key* cannot change without recreating the
/// table and copying every row across. `m.alterTable` does that copy, and the
/// migration test exists because "drift does the copy" is a claim, not a
/// guarantee about this schema.
///
/// Version 4 is the cheap kind, and it is here to be contrasted with 3. The
/// `sync` feature's `OutboxStore` port — which arrived after this table did —
/// needs a conflict policy, a scheduled retry instant and a blocked reason per
/// row. All three append, so sqlite adds them to the existing table without
/// touching a byte of the rows already there. The one decision that is not
/// mechanical is the *default*: rows queued by an older release get
/// `lastWriteWins`, the policy that cannot lose the device's work. Defaulting
/// to "the server wins" would have discarded whatever a courier did before
/// the upgrade, silently.
@DriftDatabase(
  tables: [KeyValueEntries, OutboxEntries],
  daos: [KeyValueDao, OutboxDao],
)
class PeykDatabase extends _$PeykDatabase {
  /// Opens the database over the given executor.
  ///
  /// The parameter is named `e` because drift's generated superclass names it
  /// that, and `matching_super_parameters` — on in this workspace so that a
  /// forwarded argument cannot quietly change meaning — requires the two to
  /// agree.
  PeykDatabase(super.e);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      // Sequential and cumulative: a device that skipped a release arrives
      // here with `from` several versions behind, so every step from its
      // version onwards has to run. Writing this as a switch on `from` is the
      // bug that ships an app which upgrades 2->3 correctly and 1->3 not at
      // all.
      if (from < 2) {
        await migrator.createTable(outboxEntries);
      }
      if (from < 3) {
        await migrator.alterTable(
          TableMigration(
            keyValueEntries,
            newColumns: [keyValueEntries.namespace],
            columnTransformer: {
              // Every row that predates namespacing belongs to the namespace
              // the adapter uses when a caller does not name one. Anything
              // else would strand the values written before the upgrade.
              keyValueEntries.namespace: const Constant<String>('default'),
            },
          ),
        );
      }
      // `from >= 2` is not redundant, and leaving it out is the bug this
      // schema found the first time it was run. `createTable` above builds
      // outbox_entries from *today's* class, three new columns included — so a
      // device upgrading from version 1 already has them, and adding them
      // again fails with "duplicate column name". Every step that creates a
      // table has this hazard: the steps after it must not assume the table
      // they see is the one that version originally shipped.
      if (from >= 2 && from < 4) {
        // Appended, not rebuilt. Written as three addColumn calls rather than
        // one alterTable: adding a column is a statement sqlite performs in
        // place, and routing it through a table migration would recreate
        // outbox_entries and copy every queued row for no reason.
        await migrator.addColumn(outboxEntries, outboxEntries.conflictPolicy);
        await migrator.addColumn(outboxEntries, outboxEntries.nextAttemptAt);
        await migrator.addColumn(outboxEntries, outboxEntries.blockedReason);
      }
      if (from < 5) {
        // Created rather than rebuilt: an index is derived data, so sqlite
        // builds it from the rows already there in one pass and nothing is
        // copied. The name is stated on the table class so that this step and
        // `createAll` cannot disagree about it.
        await migrator.create(outboxDrain);
      }
    },
    beforeOpen: (details) async {
      // sqlite has foreign keys off by default, per connection, so this has to
      // be set every time a connection opens rather than once at creation.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
