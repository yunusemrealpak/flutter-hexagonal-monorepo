@Tags(['unit'])
library;

import 'package:delivery_api/delivery_api.dart';
import 'package:delivery_testing/delivery_testing.dart';
import 'package:test/test.dart';

void main() {
  group('FakeDeliveryRepository', () {
    test('returns what it was given', () async {
      final repository = FakeDeliveryRepository()..give('id', 'value');

      final result = await repository.byId('id');

      expect(result.fold((value) => value, (failure) => '$failure'), 'value');
    });

    test('can be told to fail, so failure branches stay tested', () async {
      final repository = FakeDeliveryRepository()
        ..give('id', 'value')
        ..failNextWith(const DeliveryUnavailable());

      final result = await repository.byId('id');

      expect(result.isFailure, isTrue);
    });
  });
}
