@Tags(['unit'])
library;

import 'package:identity_api/identity_api.dart';
import 'package:identity_testing/identity_testing.dart';
import 'package:test/test.dart';

void main() {
  group('FakeIdentityRepository', () {
    test('returns what it was given', () async {
      final repository = FakeIdentityRepository()..give('id', 'value');

      final result = await repository.byId('id');

      expect(result.fold((value) => value, (failure) => '$failure'), 'value');
    });

    test('can be told to fail, so failure branches stay tested', () async {
      final repository = FakeIdentityRepository()
        ..give('id', 'value')
        ..failNextWith(const IdentityUnavailable());

      final result = await repository.byId('id');

      expect(result.isFailure, isTrue);
    });
  });
}
