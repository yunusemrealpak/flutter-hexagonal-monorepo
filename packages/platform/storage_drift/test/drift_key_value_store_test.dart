@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:core_testing/core_testing.dart';
import 'package:drift/native.dart';
import 'package:storage_drift/storage_drift.dart';
import 'package:test/test.dart';

void main() {
  late PeykDatabase database;
  late FakeClock clock;
  late DriftKeyValueStore store;

  setUp(() {
    database = PeykDatabase(NativeDatabase.memory());
    clock = FakeClock();
    store = DriftKeyValueStore(KeyValueDao(database), clock);
  });

  tearDown(() async => database.close());

  group('DriftKeyValueStore', () {
    test('reads back what it wrote', () async {
      await store.write('locale', 'tr-TR');

      final result = await store.read('locale');

      expect(result, const Success<String?, StoreFailure>('tr-TR'));
    });

    test('reports a missing key as a successful read of nothing', () async {
      final result = await store.read('never.written');

      // The port promises this: a missing key is not a failure, and a caller
      // that had to distinguish "absent" from "broken" by catching would get
      // it wrong at one of its call sites.
      expect(result, const Success<String?, StoreFailure>(null));
    });

    test('replaces the value at a key that already exists', () async {
      await store.write('locale', 'tr-TR');
      await store.write('locale', 'en-GB');

      expect(
        await store.read('locale'),
        const Success<String?, StoreFailure>('en-GB'),
      );
      expect((await store.keys()).fold((keys) => keys, (_) => <String>{}), {
        'locale',
      });
    });

    test(
      'stamps writes from the injected clock, not the system clock',
      () async {
        clock.advance(const Duration(hours: 3));

        await store.write('locale', 'tr-TR');

        final entry = await KeyValueDao(database).find('default', 'locale');
        // Rule A1 in one assertion: the stamp is a value this test chose, so it
        // can be asserted on exactly rather than approximately.
        expect(entry?.updatedAt, clock.now());
      },
    );

    test('deleting a key that was never written succeeds', () async {
      final result = await store.delete('never.written');

      expect(result.isSuccess, isTrue);
    });

    test('keeps namespaces apart', () async {
      final shipments = DriftKeyValueStore(
        KeyValueDao(database),
        clock,
        namespace: 'shipments',
      );
      final payments = DriftKeyValueStore(
        KeyValueDao(database),
        clock,
        namespace: 'payments',
      );

      await shipments.write('cursor', 'shipments-cursor');
      await payments.write('cursor', 'payments-cursor');

      // Two features storing `cursor` is not a collision to be resolved by
      // convention over key names; the schema makes it impossible.
      expect(
        await shipments.read('cursor'),
        const Success<String?, StoreFailure>('shipments-cursor'),
      );
      expect(
        await payments.read('cursor'),
        const Success<String?, StoreFailure>('payments-cursor'),
      );
      expect((await shipments.keys()).fold((keys) => keys, (_) => <String>{}), {
        'cursor',
      });
    });

    test(
      'turns a sqlite error into a failure instead of an exception',
      () async {
        await store.write('locale', 'tr-TR');
        // The table the adapter reads from, removed underneath it. Closing the
        // database would not do: drift reopens a memory database on the next
        // statement, so the read would succeed against an empty one.
        await database.customStatement('DROP TABLE key_value_entries');

        final result = await store.read('locale');

        // Invariant 1.2.9. The adapter is where sqlite stops being able to
        // interrupt a caller.
        expect(result.isFailure, isTrue);
        expect(
          (result as Failed<String?, StoreFailure>).failure,
          isA<StoreUnavailable>(),
        );
      },
    );
  });
}
