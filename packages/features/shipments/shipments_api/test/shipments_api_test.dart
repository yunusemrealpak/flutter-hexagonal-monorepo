@Tags(['unit'])
library;

import 'package:shipments_api/shipments_api.dart';
import 'package:test/test.dart';

void main() {
  group('ShipmentsFailure', () {
    test('is exhaustively matchable', () {
      const failures = <ShipmentsFailure>[
        ShipmentsNotFound('id'),
        ShipmentsUnavailable(),
      ];

      final described = failures
          .map(
            (failure) => switch (failure) {
              ShipmentsNotFound(:final id) => 'missing $id',
              ShipmentsUnavailable() => 'unknown',
            },
          )
          .toList();

      expect(described, ['missing id', 'unknown']);
    });
  });
}
