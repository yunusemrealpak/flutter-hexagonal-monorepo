@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:payments_api/payments_api.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  group('Money', () {
    test('refuses a negative amount', () {
      // A refund is a direction, not a negative amount. Allowing both
      // spellings would mean two places to get the sign wrong.
      expect(
        Money.of(minorUnits: -1, currency: Currency.tryLira),
        isA<Failed<Money, PaymentsFailure>>(),
      );
    });

    test('adds exactly, however many times', () {
      // The reason minor units are an int. Four hundred collections of 0.1 in
      // doubles is off by an amount somebody has to explain at the end of a
      // day.
      var total = Fixtures.lira(0);
      for (var i = 0; i < 400; i++) {
        total = Fixtures.unwrap(total.plus(Fixtures.lira(10)));
      }

      expect(total.minorUnits, 4000);
    });

    test('refuses to add two currencies', () {
      // The one arithmetic mistake in this feature that silently produces a
      // plausible number.
      final refused = Fixtures.lira(1000).plus(Fixtures.euro(1000));

      expect(
        (refused as Failed<Money, PaymentsFailure>).failure,
        isA<CurrencyMismatch>(),
      );
    });

    test('refuses to take out more than went in', () {
      // Routed through Money.of, which is the point of having one
      // construction: the negative check is written once.
      expect(
        Fixtures.lira(100).minus(Fixtures.lira(500)),
        isA<Failed<Money, PaymentsFailure>>(),
      );
    });

    test('is equal by amount and currency', () {
      expect(Fixtures.lira(4500), Fixtures.lira(4500));
      expect(Fixtures.lira(4500), isNot(Fixtures.euro(4500)));
    });

    test('carries the scale its currency actually has', () {
      // A currency with three minor-unit digits or none breaks any code that
      // assumed a hundred.
      expect(Currency.tryLira.minorUnitDigits, 2);
      expect(Currency.fromCode('try'), Currency.tryLira);
      expect(Currency.fromCode('JPY'), isNull);
    });
  });

  group('IdempotencyKey', () {
    test('refuses an empty value', () {
      expect(
        IdempotencyKey.parse('  '),
        isA<Failed<IdempotencyKey, PaymentsFailure>>(),
      );
    });
  });

  group('references', () {
    test('report a foreign identifier as a payments failure', () {
      // A failure belongs to the package that owns the port. A PaymentsGateway
      // promising PaymentsFailure may not hand back one of shipments'.
      expect(
        (ShipmentReference.parse('') as Failed<Object, PaymentsFailure>)
            .failure,
        isA<MalformedPaymentValue>(),
      );
      expect(
        (CourierReference.parse('') as Failed<Object, PaymentsFailure>).failure,
        isA<MalformedPaymentValue>(),
      );
    });
  });
}
