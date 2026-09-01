@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:core_testing/core_testing.dart';
import 'package:drift/native.dart';
import 'package:storage_drift/storage_drift.dart' as db;
import 'package:sync_api/sync_api.dart';
import 'package:sync_infrastructure/sync_infrastructure.dart';
import 'package:sync_testing/sync_testing.dart';
import 'package:test/test.dart';

/// `accepted` is one fact, and this is where that is proved.
///
/// The contract kit deliberately does not assert it: it has no way to make an
/// arbitrary store fail *between* its two writes, and an assertion that cannot
/// produce the failure it describes is a paragraph pretending to be a test.
/// Here there is a real database, so the failure can be produced — by taking
/// away the table the second write needs.
///
/// What is at stake if the two writes are not atomic: a device that dropped
/// the row and kept the old cursor comes back having forgotten work the server
/// has, and sends its next envelope from a position the server has already
/// told it is stale.
void main() {
  late db.PeykDatabase database;
  late DriftOutboxStore store;

  setUp(() async {
    database = db.PeykDatabase(NativeDatabase.memory());
    store = DriftOutboxStore(
      entries: db.OutboxDao(database),
      values: db.KeyValueDao(database),
      clock: FakeClock(),
    );
    // Forces the migration to run before anything below drops a table.
    await store.pending();
  });

  tearDown(() => database.close());

  Future<OutboxEntry> queue(String id) async {
    final entry = OutboxEntryBuilder().withId(id).build();
    expect((await store.put(entry)).isSuccess, isTrue);
    return entry;
  }

  test('rolls the drop back when the cursor write fails', () async {
    final entry = await queue('e-1');
    await store.saveCursor(const SyncCursor('c-1'));

    // The second write's table is gone, so the write inside the transaction
    // throws. Nothing else in this class can be made to fail halfway.
    await database.customStatement('DROP TABLE key_value_entries');

    final accepted = await store.accepted(entry.id, const SyncCursor('c-9'));

    expect(accepted.isFailure, isTrue);
    final pending = (await store.pending()).fold(
      (value) => value,
      (failure) => throw StateError('$failure'),
    );
    // Still queued. Without the transaction the delete would have committed
    // and the work would be gone with the server never having been asked.
    expect(pending.map((entry) => entry.id.value), ['e-1']);
  });

  test('commits both halves when nothing fails', () async {
    final entry = await queue('e-1');

    expect(
      (await store.accepted(entry.id, const SyncCursor('c-9'))).isSuccess,
      isTrue,
    );

    final pending = (await store.pending()).fold(
      (value) => value,
      (failure) => throw StateError('$failure'),
    );
    expect(pending, isEmpty);
    expect(
      await store.cursor(),
      const Success<SyncCursor, SyncFailure>(SyncCursor('c-9')),
    );
  });
}
