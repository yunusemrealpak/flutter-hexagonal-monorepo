import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:storage_drift/storage_drift.dart' as db;
import 'package:sync_api/sync_api.dart';

import 'outbox_row_mapper.dart';

/// Answers `OutboxStore` over the application's sqlite database.
///
/// This is the adapter `app_courier` binds, and the reason the port exists at
/// all: an offline-first courier app has to survive the operating system
/// reclaiming it mid-shift, and a queue in memory does not. `app_dispatcher`
/// binds `InMemoryOutboxStore` instead — an operator is at a desk with a
/// connection, so a database file costs something and buys nothing there.
///
/// Two things stop here and go no further up. **SQL**, obviously. And
/// **exceptions**: a DAO below this line is allowed to throw, and every method
/// here catches, because invariant 1.2.9 says nothing crosses a port boundary
/// as an exception. The adapter is the boundary.
///
/// `storage_drift` is imported with a prefix because it exports a type called
/// `OutboxEntry` too — drift generates one per table. That collision is worth
/// keeping rather than renaming around: the two shapes are allowed to differ,
/// and having both spellings visible is what makes the mapper's job obvious.
///
/// The cursor is stored in `key_value_entries` rather than in a table of its
/// own. It is a single opaque string per device, which is exactly what that
/// table is for, and a table with one row in it is a migration nobody needed.
final class DriftOutboxStore implements OutboxStore {
  /// Creates the adapter over the two DAOs it needs.
  ///
  /// Two DAOs rather than a `PeykDatabase`, so that what this class can reach
  /// is visible in its constructor: the outbox table and one namespace of the
  /// key-value table, and nothing else in the schema.
  const DriftOutboxStore({
    required this.entries,
    required this.values,
    required this.clock,
  });

  /// The namespace the cursor is filed under.
  ///
  /// Namespaced so that clearing sync's stored state on sign-out is one call
  /// rather than a list of key names that has to be kept in step.
  static const String namespace = 'sync';

  /// The key the cursor is stored at within [namespace].
  static const String cursorKey = 'cursor';

  /// Every statement the outbox table answers.
  final db.OutboxDao entries;

  /// Where the cursor is kept.
  final db.KeyValueDao values;

  /// Stamps the cursor write. Rule A1: even a row nobody reads the timestamp
  /// of gets it from the port, because the alternative is one call site that
  /// makes the suite depend on when it runs.
  final Clock clock;

  @override
  Future<Result<void, SyncFailure>> put(OutboxEntry entry) => _guard(
    () async => entries.enqueue(OutboxRowMapper.toRow(entry)),
  );

  @override
  Future<Result<OutboxEntry, SyncFailure>> byId(OutboxEntryId id) async {
    final row = await _guard(() => entries.byId(id.value));
    return row.flatMap(
      (value) => value == null
          ? Failed(
              MalformedEntry(field: 'id', reason: 'no entry ${id.value}'),
            )
          : OutboxRowMapper.toDomain(value),
    );
  }

  @override
  Future<Result<List<OutboxEntry>, SyncFailure>> pending({
    int limit = 50,
  }) async {
    final rows = await _guard(() => entries.pending(limit: limit));
    return rows.flatMap(_toDomainList);
  }

  @override
  Future<Result<List<OutboxEntry>, SyncFailure>> blocked() async {
    final rows = await _guard(entries.blocked);
    return rows.flatMap(_toDomainList);
  }

  @override
  Future<Result<void, SyncFailure>> drop(OutboxEntryId id) =>
      _guard(() => entries.drop(id.value));

  @override
  Future<Result<SyncCursor, SyncFailure>> cursor() async {
    final stored = await _guard(() => values.find(namespace, cursorKey));
    // A device that has never synchronised has no row, and that is a state
    // rather than a fault. Reporting it as a failure would make the first
    // drain after an install look like a broken database.
    return stored.map(
      (entry) => entry == null ? SyncCursor.beginning : SyncCursor(entry.value),
    );
  }

  @override
  Future<Result<void, SyncFailure>> saveCursor(SyncCursor cursor) => _guard(
    () => values.put(
      namespace: namespace,
      key: cursorKey,
      value: cursor.value,
      updatedAt: clock.now(),
    ),
  );

  Result<List<OutboxEntry>, SyncFailure> _toDomainList(
    List<db.OutboxEntry> rows,
  ) {
    final entries = <OutboxEntry>[];
    for (final row in rows) {
      // One unreadable row fails the whole read rather than being skipped. A
      // queue that quietly omits an entry is work nobody sends and nobody
      // misses until a depot counts the money.
      switch (OutboxRowMapper.toDomain(row)) {
        case Failed(:final failure):
          return Failed(failure);
        case Success(:final value):
          entries.add(value);
      }
    }
    return Success(entries);
  }

  /// Runs a DAO call and turns anything it throws into a `SyncFailure`.
  ///
  /// The one place this package catches. Below it, drift and sqlite are
  /// entitled to throw; above it, nothing but a `Result` crosses.
  ///
  /// Everything collapses to `OutboxUnavailable`, and that is deliberate. The
  /// caller behaves identically for a locked database, a full disk and a
  /// corrupt file: it stops the drain, because a store that cannot be trusted
  /// to remember must not be written into. `storeFailureFrom` in
  /// `storage_drift` makes finer distinctions for the `KeyValueStore` port
  /// because *that* port's callers act on them; this one's do not, and
  /// inventing cases nobody branches on is how a sealed union stops being
  /// worth matching over.
  Future<Result<T, SyncFailure>> _guard<T>(Future<T> Function() run) async {
    try {
      return Success(await run());
    } on Object catch (error) {
      return Failed(OutboxUnavailable(detail: error.toString()));
    }
  }
}
