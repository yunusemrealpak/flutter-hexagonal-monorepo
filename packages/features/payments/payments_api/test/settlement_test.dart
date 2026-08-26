@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:payments_api/payments_api.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  group('Settlement', () {
    test('is identified by the courier and the day', () {
      // Derived rather than minted, and this is the case where deriving is
      // right: a courier has exactly one settlement per day, so two devices
      // computing the identifier independently have to agree.
      final morning = Fixtures.unwrap(
        SettlementId.forDay('courier-1', Fixtures.noon),
      );
      final evening = Fixtures.unwrap(
        SettlementId.forDay(
          'courier-1',
          Fixtures.noon.add(const Duration(hours: 8)),
        ),
      );

      expect(morning, evening);
      expect(morning.value, 'courier-1:2026-03-14');
    });

    test('counts cash that was taken', () {
      final day = Fixtures.unwrap(Fixtures.day().including(Fixtures.taken()));

      expect(day.collected, Fixtures.lira(4500));
      expect(Fixtures.unwrap(day.owed), Fixtures.lira(4500));
    });

    test('ignores a card, which never passed through anybody s hands', () {
      // Counting it would ask a courier to hand over money they never held.
      final day = Fixtures.unwrap(
        Fixtures.day().including(
          Fixtures.taken(method: const PaymentMethod.card(last4: '4242')),
        ),
      );

      expect(day.collected.isZero, isTrue);
    });

    test('ignores an attempt that never settled', () {
      // Which is why a caller can hand it every attempt of the day without
      // filtering first, and why the filter cannot drift between callers.
      final day = Fixtures.unwrap(
        Fixtures.day().including(Fixtures.attempt()),
      );

      expect(day.collected.isZero, isTrue);
    });

    test('a refund leaves both halves visible', () {
      final refunded = Fixtures.unwrap(
        Fixtures.taken().refunded(at: Fixtures.noon),
      );

      final day = Fixtures.unwrap(Fixtures.day().including(refunded));

      expect(day.collected, Fixtures.lira(4500));
      expect(day.refunded, Fixtures.lira(4500));
      expect(Fixtures.unwrap(day.owed).isZero, isTrue);
    });

    test('adds up an afternoon', () {
      var day = Fixtures.day();
      for (final amount in [4500, 1200, 300]) {
        day = Fixtures.unwrap(
          day.including(
            Fixtures.taken(keyValue: 'pay-$amount', minorUnits: amount),
          ),
        );
      }

      expect(Fixtures.unwrap(day.owed), Fixtures.lira(6000));
    });

    test('is restored with the totals a store kept, not replayed', () {
      // Unlike DeliveryAttempt, a settlement is an aggregate: replaying it
      // would mean reading every attempt of the day back out of somewhere,
      // which is what storing the total was for. The guard is in the store's
      // contract kit instead.
      final restored = Settlement.restored(
        id: Fixtures.unwrap(SettlementId.forDay('courier-1', Fixtures.noon)),
        courier: Fixtures.courier(),
        day: Fixtures.noon,
        collected: Fixtures.lira(6000),
        refunded: Fixtures.lira(500),
      );

      expect(Fixtures.unwrap(restored.owed), Fixtures.lira(5500));
      expect(restored.isOpen, isTrue);
      expect(restored.day, DateTime.utc(2026, 3, 14));
    });

    test('closing is one way', () {
      // A day that has been handed in and counted is a day somebody signed
      // for. A settlement that could reopen would let a late collection change
      // a number after the money was counted.
      final closed = Fixtures.unwrap(Fixtures.day().close(at: Fixtures.noon));

      expect(closed.isOpen, isFalse);
      expect(
        closed.close(at: Fixtures.noon),
        isA<Failed<Settlement, PaymentsFailure>>(),
      );
      expect(
        closed.including(Fixtures.taken()),
        isA<Failed<Settlement, PaymentsFailure>>(),
      );
    });
  });
}
