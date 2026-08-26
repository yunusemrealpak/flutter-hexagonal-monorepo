@Tags(['unit'])
library;

import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:storage_drift/storage_drift.dart';
import 'package:test/test.dart';

/// The `key_value_entries` table as schema version 1 shipped it: no namespace,
/// and `key` alone as the primary key.
const _schemaV1KeyValueEntries = '''
CREATE TABLE key_value_entries (
  key TEXT NOT NULL,
  value TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  PRIMARY KEY (key)
);
''';

/// `outbox_entries` as schema version 2 added it, before version 4 appended
/// the three columns the `sync` feature's port needs.
const _schemaV2OutboxEntries = '''
CREATE TABLE outbox_entries (
  id TEXT NOT NULL,
  feature TEXT NOT NULL,
  operation TEXT NOT NULL,
  payload TEXT NOT NULL,
  created_at TEXT NOT NULL,
  attempt_count INTEGER NOT NULL DEFAULT 0,
  last_attempt_at TEXT,
  PRIMARY KEY (id)
);
''';

/// `key_value_entries` as schema version 3 left it: namespaced, and with the
/// namespace joined to the primary key.
const _schemaV3KeyValueEntries = '''
CREATE TABLE key_value_entries (
  key TEXT NOT NULL,
  value TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  namespace TEXT NOT NULL DEFAULT 'default',
  PRIMARY KEY (namespace, key)
);
''';

/// Builds a database that looks exactly like one an older release left behind.
///
/// The old schema is written as raw SQL rather than generated from the current
/// table classes, and that is the whole point: a migration test that describes
/// the old schema in terms of the new one proves nothing, because the same
/// mistake would be present on both sides of the comparison.
sqlite.Database _databaseAtVersion(int version, {required List<String> ddl}) {
  final database = sqlite.sqlite3.openInMemory();
  ddl.forEach(database.execute);
  database.execute('PRAGMA user_version = $version');
  return database;
}

/// Drift runs migrations lazily, on the first statement. This is that
/// statement.
Future<void> _open(PeykDatabase database) =>
    database.customSelect('SELECT 1').get();

void main() {
  group('migrating from schema version 1', () {
    late sqlite.Database raw;
    late PeykDatabase database;

    setUp(() {
      raw = _databaseAtVersion(1, ddl: [_schemaV1KeyValueEntries])
        ..execute('''
INSERT INTO key_value_entries (key, value, updated_at) VALUES
  ('sync.cursor', '2026-01-01T09:00:00Z', '2026-01-01T09:00:00.000Z'),
  ('locale', 'tr-TR', '2026-01-01T09:00:00.000Z')
''');
      database = PeykDatabase(NativeDatabase.opened(raw));
    });

    tearDown(() async => database.close());

    test('keeps every stored value across the primary key rebuild', () async {
      await _open(database);

      final dao = KeyValueDao(database);
      final cursor = await dao.find('default', 'sync.cursor');
      final locale = await dao.find('default', 'locale');

      // Version 3 could not append `namespace`: it joined the primary key, so
      // sqlite had to recreate the table and copy every row across. This is
      // the assertion that turns "drift does the copy" from a claim into a
      // checked fact about this schema.
      expect(cursor?.value, '2026-01-01T09:00:00Z');
      expect(locale?.value, 'tr-TR');
      expect(await dao.keysIn('default'), {'sync.cursor', 'locale'});
    });

    test('files pre-namespace rows under the default namespace', () async {
      await _open(database);

      // Anything else would strand values written before the upgrade: the
      // adapter reads from `default` unless told otherwise, so rows filed
      // anywhere else would simply stop being found.
      final rows = raw.select('SELECT namespace FROM key_value_entries');
      expect(rows.map((row) => row['namespace']), everyElement('default'));
    });

    test('creates the outbox table that version 2 introduced', () async {
      await _open(database);

      final dao = OutboxDao(database);
      await dao.enqueue(
        OutboxEntry(
          id: 'OBX-1',
          feature: 'shipments',
          operation: 'assign',
          payload: '{"courierId":"CUR-9"}',
          createdAt: DateTime.utc(2026, 1, 1, 9),
          attemptCount: 0,
          conflictPolicy: 'lastWriteWins',
        ),
      );

      expect(await dao.pending(), hasLength(1));
    });

    test('leaves the database at the current schema version', () async {
      await _open(database);

      expect(raw.userVersion, 4);
    });
  });

  group('migrating from schema version 2', () {
    test('keeps queued outbox work as well as stored values', () async {
      final raw =
          _databaseAtVersion(
              2,
              ddl: [_schemaV1KeyValueEntries, _schemaV2OutboxEntries],
            )
            ..execute('''
INSERT INTO key_value_entries (key, value, updated_at) VALUES
  ('sync.cursor', 'v2', '2026-01-01T09:00:00.000Z')
''')
            ..execute('''
INSERT INTO outbox_entries
  (id, feature, operation, payload, created_at, attempt_count) VALUES
  ('OBX-7', 'delivery', 'complete', '{}', '2026-01-01T09:00:00.000Z', 2)
''');
      final database = PeykDatabase(NativeDatabase.opened(raw));
      addTearDown(database.close);

      await _open(database);

      // The 2 -> 3 step touches only key_value_entries. Work a courier queued
      // while offline must not be a casualty of a table rebuild elsewhere.
      final queued = await OutboxDao(database).pending();
      expect(queued, hasLength(1));
      expect(queued.single.id, 'OBX-7');
      expect(queued.single.attemptCount, 2);
      expect(
        (await KeyValueDao(database).find('default', 'sync.cursor'))?.value,
        'v2',
      );
    });

    test('gives pre-version-4 rows the policy that keeps their work', () async {
      final raw =
          _databaseAtVersion(
            2,
            ddl: [_schemaV1KeyValueEntries, _schemaV2OutboxEntries],
          )..execute('''
INSERT INTO outbox_entries
  (id, feature, operation, payload, created_at, attempt_count) VALUES
  ('OBX-7', 'delivery', 'complete', '{}', '2026-01-01T09:00:00.000Z', 2)
''');
      final database = PeykDatabase(NativeDatabase.opened(raw));
      addTearDown(database.close);

      await _open(database);

      // The only non-mechanical decision in the 3 -> 4 step. Defaulting to
      // "the server wins" would have discarded whatever a courier did before
      // the upgrade, silently and with no record left behind.
      final queued = await OutboxDao(database).pending();
      expect(queued.single.conflictPolicy, 'lastWriteWins');
      expect(queued.single.nextAttemptAt, isNull);
      expect(queued.single.blockedReason, isNull);
    });
  });

  group('migrating from schema version 3', () {
    test('appends the outbox columns without touching the rows', () async {
      final raw =
          _databaseAtVersion(
            3,
            ddl: [_schemaV3KeyValueEntries, _schemaV2OutboxEntries],
          )..execute('''
INSERT INTO outbox_entries
  (id, feature, operation, payload, created_at, attempt_count) VALUES
  ('OBX-1', 'payments', 'collect', '{"amount":1200}', '2026-01-01T09:00:00.000Z', 3),
  ('OBX-2', 'delivery', 'complete', '{}', '2026-01-01T10:00:00.000Z', 0)
''');
      final database = PeykDatabase(NativeDatabase.opened(raw));
      addTearDown(database.close);

      await _open(database);

      // Three appended columns, so sqlite adds them in place. This is the
      // cheap kind of migration, and the assertion that says so is that both
      // payloads and both attempt counts survived unchanged.
      final queued = await OutboxDao(database).pending();
      expect(queued.map((row) => row.id), ['OBX-1', 'OBX-2']);
      expect(queued.first.payload, '{"amount":1200}');
      expect(queued.first.attemptCount, 3);
      expect(raw.userVersion, 4);
    });

    test('reads nothing as blocked until something is', () async {
      final raw =
          _databaseAtVersion(
            3,
            ddl: [_schemaV3KeyValueEntries, _schemaV2OutboxEntries],
          )..execute('''
INSERT INTO outbox_entries
  (id, feature, operation, payload, created_at, attempt_count) VALUES
  ('OBX-1', 'payments', 'collect', '{}', '2026-01-01T09:00:00.000Z', 0)
''');
      final database = PeykDatabase(NativeDatabase.opened(raw));
      addTearDown(database.close);

      await _open(database);

      expect(await OutboxDao(database).blocked(), isEmpty);
    });
  });

  group('creating a fresh database', () {
    test('starts at the current schema version with both tables', () async {
      final database = PeykDatabase(NativeDatabase.memory());
      addTearDown(database.close);

      await _open(database);

      expect(database.schemaVersion, 4);
      expect(await KeyValueDao(database).keysIn('default'), isEmpty);
      expect(await OutboxDao(database).pending(), isEmpty);
    });
  });
}
