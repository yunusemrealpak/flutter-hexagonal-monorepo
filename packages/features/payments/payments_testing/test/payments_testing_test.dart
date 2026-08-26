@Tags(['unit'])
library;

import 'package:payments_api/payments_api.dart';
import 'package:payments_testing/payments_testing.dart';
import 'package:test/test.dart';

void main() {
  group('FakePaymentsRepository', () {
    test('returns what it was given', () async {
      final repository = FakePaymentsRepository()..give('id', 'value');

      final result = await repository.byId('id');

      expect(result.fold((value) => value, (failure) => '$failure'), 'value');
    });

    test('can be told to fail, so failure branches stay tested', () async {
      final repository = FakePaymentsRepository()
        ..give('id', 'value')
        ..failNextWith(const PaymentsUnavailable());

      final result = await repository.byId('id');

      expect(result.isFailure, isTrue);
    });
  });
}
