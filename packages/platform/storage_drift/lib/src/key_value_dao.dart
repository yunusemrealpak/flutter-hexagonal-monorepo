import 'package:drift/drift.dart';
import 'key_value_entries.dart';
import 'peyk_database.dart';

part 'key_value_dao.g.dart';

/// Every query the key-value table answers.
///
/// A data access object rather than queries written inline in the adapter, so
/// that the SQL a table can be asked for lives next to the table's definition.
/// When the schema changes, the set of statements to re-check is this file
/// instead of every call site.
@DriftAccessor(tables: [KeyValueEntries])
class KeyValueDao extends DatabaseAccessor<PeykDatabase>
    with _$KeyValueDaoMixin {
  /// Reads and writes through the attached database.
  KeyValueDao(super.attachedDatabase);

  /// The entry at [key] within [namespace], or `null` when there is none.
  Future<KeyValueEntry?> find(String namespace, String key) {
    return (select(keyValueEntries)..where(
          (row) => row.namespace.equals(namespace) & row.key.equals(key),
        ))
        .getSingleOrNull();
  }

  /// Writes [value] at [key], replacing whatever was there.
  Future<void> put({
    required String namespace,
    required String key,
    required String value,
    required DateTime updatedAt,
  }) {
    return into(keyValueEntries).insertOnConflictUpdate(
      KeyValueEntriesCompanion.insert(
        namespace: Value(namespace),
        key: key,
        value: value,
        updatedAt: updatedAt,
      ),
    );
  }

  /// Removes [key] from [namespace]. Removing what is not there is a no-op.
  Future<void> remove(String namespace, String key) {
    return (delete(keyValueEntries)..where(
          (row) => row.namespace.equals(namespace) & row.key.equals(key),
        ))
        .go();
  }

  /// Every key stored in [namespace].
  Future<Set<String>> keysIn(String namespace) async {
    final query = selectOnly(keyValueEntries)
      ..addColumns([keyValueEntries.key])
      ..where(keyValueEntries.namespace.equals(namespace));
    final rows = await query.get();
    return rows.map((row) => row.read(keyValueEntries.key)!).toSet();
  }
}
