@Tags(['unit'])
library;

import 'package:routing_api/routing_api.dart';
import 'package:test/test.dart';

void main() {
  group('RoutingFailure', () {
    test('is exhaustively matchable', () {
      const failures = <RoutingFailure>[
        RoutingNotFound('id'),
        RoutingUnavailable(),
      ];

      final described = failures
          .map(
            (failure) => switch (failure) {
              RoutingNotFound(:final id) => 'missing $id',
              RoutingUnavailable() => 'unknown',
            },
          )
          .toList();

      expect(described, ['missing id', 'unknown']);
    });
  });
}
