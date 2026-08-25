@Tags(['unit'])
library;

import 'package:identity_api/identity_api.dart';
import 'package:test/test.dart';

void main() {
  group('IdentityFailure', () {
    test('is exhaustively matchable', () {
      const failures = <IdentityFailure>[
        IdentityNotFound('id'),
        IdentityUnavailable(),
      ];

      final described = failures
          .map(
            (failure) => switch (failure) {
              IdentityNotFound(:final id) => 'missing $id',
              IdentityUnavailable() => 'unknown',
            },
          )
          .toList();

      expect(described, ['missing id', 'unknown']);
    });
  });
}
