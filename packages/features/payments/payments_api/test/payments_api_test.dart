@Tags(['unit'])
library;

import 'package:payments_api/payments_api.dart';
import 'package:test/test.dart';

void main() {
  group('PaymentsFailure', () {
    test('is exhaustively matchable', () {
      const failures = <PaymentsFailure>[
        PaymentsNotFound('id'),
        PaymentsUnavailable(),
      ];

      final described = failures
          .map(
            (failure) => switch (failure) {
              PaymentsNotFound(:final id) => 'missing $id',
              PaymentsUnavailable() => 'unknown',
            },
          )
          .toList();

      expect(described, ['missing id', 'unknown']);
    });
  });
}
