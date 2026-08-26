@Tags(['unit'])
library;

import 'package:sync_api/sync_api.dart';
import 'package:sync_testing/sync_testing.dart';
import 'package:test/test.dart';

void main() {
  group('FakeSyncRepository', () {
    test('returns what it was given', () async {
      final repository = FakeSyncRepository()..give('id', 'value');

      final result = await repository.byId('id');

      expect(result.fold((value) => value, (failure) => '$failure'), 'value');
    });

    test('can be told to fail, so failure branches stay tested', () async {
      final repository = FakeSyncRepository()
        ..give('id', 'value')
        ..failNextWith(const SyncUnavailable());

      final result = await repository.byId('id');

      expect(result.isFailure, isTrue);
    });
  });
}
