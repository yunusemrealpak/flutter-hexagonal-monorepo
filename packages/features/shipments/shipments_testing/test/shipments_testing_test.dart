@Tags(['unit'])
library;

import 'package:shipments_api/shipments_api.dart';
import 'package:shipments_testing/shipments_testing.dart';
import 'package:test/test.dart';

void main() {
  group('FakeShipmentsRepository', () {
    test('returns what it was given', () async {
      final repository = FakeShipmentsRepository()..give('id', 'value');

      final result = await repository.byId('id');

      expect(result.fold((value) => value, (failure) => '$failure'), 'value');
    });

    test('can be told to fail, so failure branches stay tested', () async {
      final repository = FakeShipmentsRepository()
        ..give('id', 'value')
        ..failNextWith(const ShipmentsUnavailable());

      final result = await repository.byId('id');

      expect(result.isFailure, isTrue);
    });
  });
}
