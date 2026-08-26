import 'package:payments_api/payments_api.dart';
import 'package:test/test.dart';

import 'payments_fixtures.dart';

/// The behaviour every `SettlementStore` has to have.
///
/// Smaller than the gateway kit, because the port is smaller — but the first
/// assertion in it is the one a courier notices when it is wrong: a day that
/// has not been opened reads as *nothing*, not as an error. The first
/// collection of every morning arrives before anything has been written.
///
/// [createStore] must return a fresh, empty store on every call.
void runSettlementStoreContract(SettlementStore Function() createStore) {
  group('SettlementStore contract', () {
    late SettlementStore store;

    setUp(() => store = createStore());

    test('a day nobody opened reads as nothing', () async {
      final read = await store.read('courier-1:2026-03-14');

      expect(read.fold((s) => s, (f) => throw StateError('$f')), isNull);
    });

    test('reads back the day that was written', () async {
      final day = PaymentsFixtures.day();

      await store.save(day);
      final read = await store.read(day.id.value);

      expect(
        read.fold((s) => s?.id, (f) => throw StateError('$f')),
        day.id,
      );
    });

    test('reads back the totals, not just the day', () async {
      // The assertion that catches a store which persists the identifier and
      // recomputes the money from somewhere else.
      final day = PaymentsFixtures.day()
          .including(PaymentsFixtures.taken())
          .fold((s) => s, (f) => throw StateError('$f'));

      await store.save(day);
      final read = await store.read(day.id.value);

      expect(
        read.fold((s) => s?.collected, (f) => throw StateError('$f')),
        PaymentsFixtures.lira(4500),
      );
    });

    test('keeps one settlement per day, replacing the last', () async {
      final opened = PaymentsFixtures.day();
      final withMoney = opened
          .including(PaymentsFixtures.taken())
          .fold((s) => s, (f) => throw StateError('$f'));

      await store.save(opened);
      await store.save(withMoney);
      final read = await store.read(opened.id.value);

      expect(
        read.fold((s) => s?.collected, (f) => throw StateError('$f')),
        PaymentsFixtures.lira(4500),
      );
    });

    test('remembers that a day was closed', () async {
      // Closing is one-way, and a store that forgot it would let a late
      // collection change a number after the money was counted.
      final closed = PaymentsFixtures.day()
          .close(at: PaymentsFixtures.noon)
          .fold((s) => s, (f) => throw StateError('$f'));

      await store.save(closed);
      final read = await store.read(closed.id.value);

      expect(
        read.fold((s) => s?.isOpen, (f) => throw StateError('$f')),
        isFalse,
      );
    });

    test('keeps two couriers apart', () async {
      await store.save(PaymentsFixtures.day());
      await store.save(PaymentsFixtures.day(courierId: 'courier-2'));

      final read = await store.read('courier-2:2026-03-14');

      expect(
        read.fold((s) => s?.courier.value, (f) => throw StateError('$f')),
        'courier-2',
      );
    });
  });
}
