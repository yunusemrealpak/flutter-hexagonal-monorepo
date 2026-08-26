@Tags(['unit'])
library;

import 'package:sync_api/sync_api.dart';
import 'package:test/test.dart';

void main() {
  group('SyncFailure', () {
    test('is exhaustively matchable', () {
      const failures = <SyncFailure>[SyncNotFound('id'), SyncUnavailable()];

      final described = failures
          .map(
            (failure) => switch (failure) {
              SyncNotFound(:final id) => 'missing $id',
              SyncUnavailable() => 'unknown',
            },
          )
          .toList();

      expect(described, ['missing id', 'unknown']);
    });
  });
}
