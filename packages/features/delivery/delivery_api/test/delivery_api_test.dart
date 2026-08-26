@Tags(['unit'])
library;

import 'package:delivery_api/delivery_api.dart';
import 'package:test/test.dart';

void main() {
  group('DeliveryFailure', () {
    test('is exhaustively matchable', () {
      const failures = <DeliveryFailure>[
        DeliveryNotFound('id'),
        DeliveryUnavailable(),
      ];

      final described = failures
          .map(
            (failure) => switch (failure) {
              DeliveryNotFound(:final id) => 'missing $id',
              DeliveryUnavailable() => 'unknown',
            },
          )
          .toList();

      expect(described, ['missing id', 'unknown']);
    });
  });
}
