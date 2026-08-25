@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:shipments_api/shipments_api.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  group('shape', () {
    test('accepts twelve digits whose check digit holds', () {
      expect(barcode().value, '100000000007');
    });

    test('strips whitespace anywhere, not only at the ends', () {
      const body = '10000000000';
      final digits = '$body${Barcode.checkDigitFor(body)}';
      final spaced =
          '${digits.substring(0, 4)} ${digits.substring(4, 8)} '
          '${digits.substring(8)}';

      expect(unwrap(Barcode.parse(spaced)).value, digits);
    });

    test('refuses the wrong number of digits, and says how many', () {
      expect(
        Barcode.parse('123'),
        const Failed<Barcode, ShipmentFailure>(
          MalformedBarcode(raw: '123', reason: 'expected 12 digits, got 3'),
        ),
      );
    });

    test('refuses a non-digit', () {
      expect(
        Barcode.parse('10000000000X'),
        const Failed<Barcode, ShipmentFailure>(
          MalformedBarcode(raw: '10000000000X', reason: 'contains a non-digit'),
        ),
      );
    });
  });

  group('check digit', () {
    test('refuses a number whose check digit does not hold', () {
      const body = '10000000000';
      final wrong = (Barcode.checkDigitFor(body) + 1) % 10;

      expect(
        Barcode.parse('$body$wrong'),
        Failed<Barcode, ShipmentFailure>(
          MalformedBarcode(
            raw: '$body$wrong',
            reason: 'check digit does not match',
          ),
        ),
      );
    });

    test('catches a single mistyped digit in every position', () {
      // The property the check digit is actually for. A scheme that caught
      // some positions and not others would look correct in one hand-picked
      // example and fail in the warehouse.
      const body = '38294756103';
      final valid = '$body${Barcode.checkDigitFor(body)}';

      for (var index = 0; index < body.length; index++) {
        final digit = int.parse(valid[index]);
        final mistyped = valid.replaceRange(
          index,
          index + 1,
          '${(digit + 1) % 10}',
        );

        expect(
          Barcode.parse(mistyped).isFailure,
          isTrue,
          reason: 'a wrong digit at position $index slipped through',
        );
      }
    });

    test('produces a digit in 0..9 for any body', () {
      for (var seed = 0; seed < 200; seed++) {
        final body = (10000000000 + seed * 977).toString();
        final digit = Barcode.checkDigitFor(body);

        expect(digit, inInclusiveRange(0, 9));
        expect(Barcode.parse('$body$digit').isSuccess, isTrue);
      }
    });
  });

  group('equality', () {
    test('two barcodes with the same digits are the same barcode', () {
      expect(barcode(), barcode());
      expect(barcode().hashCode, barcode().hashCode);
    });

    test('a spaced label and a bare one are the same barcode', () {
      expect(unwrap(Barcode.parse('1000 0000 0007')), barcode());
    });
  });
}
