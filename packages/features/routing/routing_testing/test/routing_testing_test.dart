@Tags(['unit'])
library;

import 'package:routing_api/routing_api.dart';
import 'package:routing_testing/routing_testing.dart';
import 'package:test/test.dart';

void main() {
  group('FakeRoutingRepository', () {
    test('returns what it was given', () async {
      final repository = FakeRoutingRepository()..give('id', 'value');

      final result = await repository.byId('id');

      expect(result.fold((value) => value, (failure) => '$failure'), 'value');
    });

    test('can be told to fail, so failure branches stay tested', () async {
      final repository = FakeRoutingRepository()
        ..give('id', 'value')
        ..failNextWith(const RoutingUnavailable());

      final result = await repository.byId('id');

      expect(result.isFailure, isTrue);
    });
  });
}
