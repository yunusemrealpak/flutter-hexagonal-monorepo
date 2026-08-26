@Tags(['unit'])
library;

import 'package:drift/native.dart';
import 'package:storage_drift/storage_drift.dart';
import 'package:test/test.dart';

OutboxEntry _entry(
  String id, {
  DateTime? createdAt,
  String? blockedReason,
}) => OutboxEntry(
  id: id,
  feature: 'delivery',
  operation: 'complete',
  payload: '{"shipmentId":"SHP-1"}',
  createdAt: createdAt ?? DateTime.utc(2026, 1, 1, 9),
  attemptCount: 0,
  conflictPolicy: 'lastWriteWins',
  blockedReason: blockedReason,
);

void main() {
  late PeykDatabase database;
  late OutboxDao dao;

  setUp(() {
    database = PeykDatabase(NativeDatabase.memory());
    dao = OutboxDao(database);
  });

  tearDown(() async => database.close());

  group('OutboxDao', () {
    test('returns pending work oldest first', () async {
      await dao.enqueue(
        _entry('OBX-2', createdAt: DateTime.utc(2026, 1, 1, 10)),
      );
      await dao.enqueue(
        _entry('OBX-1', createdAt: DateTime.utc(2026, 1, 1, 9)),
      );

      expect(
        (await dao.pending()).map((entry) => entry.id),
        ['OBX-1', 'OBX-2'],
      );
    });

    test('queueing the same id twice leaves one entry', () async {
      await dao.enqueue(_entry('OBX-1'));
      await dao.enqueue(_entry('OBX-1'));

      // Idempotent by construction: a feature that retries after a crash
      // mid-write must not end up sending its work twice.
      expect(await dao.pending(), hasLength(1));
    });

    test(
      'recording an attempt increments the count and stamps the time',
      () async {
        await dao.enqueue(_entry('OBX-1'));
        final attemptedAt = DateTime.utc(2026, 1, 1, 11);

        await dao.recordAttempt('OBX-1', attemptedAt);
        await dao.recordAttempt('OBX-1', attemptedAt);

        final entry = (await dao.pending()).single;
        // Incremented in SQL rather than read-modify-written, so two drains of
        // the same outbox cannot both write the same count.
        expect(entry.attemptCount, 2);
        expect(entry.lastAttemptAt, attemptedAt);
      },
    );

    test('dropping an entry removes it from the queue', () async {
      await dao.enqueue(_entry('OBX-1'));

      await dao.drop('OBX-1');

      expect(await dao.pending(), isEmpty);
    });

    test('honours the limit so a drain can be batched', () async {
      for (var index = 0; index < 5; index++) {
        await dao.enqueue(
          _entry('OBX-$index', createdAt: DateTime.utc(2026, 1, 1, 9 + index)),
        );
      }

      expect(await dao.pending(limit: 2), hasLength(2));
    });

    test('orders rows written in the same instant by identifier', () async {
      // Two rows queued in the same millisecond have to come back in the same
      // order on every read. Without the tie-break the order is whatever
      // sqlite chose, and a contract kit that passed against an in-memory map
      // would fail here for a reason nobody could reproduce.
      await dao.enqueue(_entry('OBX-b'));
      await dao.enqueue(_entry('OBX-a'));

      expect(
        (await dao.pending()).map((entry) => entry.id),
        ['OBX-a', 'OBX-b'],
      );
    });

    test('leaves blocked work out of the pending queue', () async {
      await dao.enqueue(_entry('OBX-1'));
      await dao.enqueue(_entry('OBX-2', blockedReason: 'rejected'));

      // One rejected entry waits for a person while everything behind it
      // keeps draining. That is the whole reason the row is excluded rather
      // than deleted.
      expect((await dao.pending()).map((entry) => entry.id), ['OBX-1']);
    });

    test('returns exactly what pending leaves out', () async {
      await dao.enqueue(_entry('OBX-1'));
      await dao.enqueue(_entry('OBX-2', blockedReason: 'rejected'));

      final blocked = await dao.blocked();
      expect(blocked.map((entry) => entry.id), ['OBX-2']);
      expect(blocked.single.blockedReason, 'rejected');
      expect(blocked.single.payload, isNotEmpty);
    });

    test('reads one entry by identifier, blocked or not', () async {
      await dao.enqueue(_entry('OBX-1', blockedReason: 'rejected'));

      expect((await dao.byId('OBX-1'))?.blockedReason, 'rejected');
      expect(await dao.byId('OBX-missing'), isNull);
    });
  });
}
