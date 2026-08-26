@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:delivery_api/delivery_api.dart';
import 'package:delivery_application/delivery_application.dart';
import 'package:test/test.dart';

void main() {
  group('LoadDelivery', () {
    test('returns what the repository holds', () async {
      final repository = _StubRepository()..records['id'] = 'value';
      final useCase = LoadDelivery(repository);

      final result = await useCase('id');

      expect(result.isSuccess, isTrue);
      expect(result.fold((value) => value, (failure) => '$failure'), 'value');
    });

    test('passes a failure through untouched', () async {
      final repository = _StubRepository();
      final useCase = LoadDelivery(repository);

      final result = await useCase('missing');

      expect(result.isFailure, isTrue);
    });
  });
}

/// A stub kept local to this file rather than pulled from a `_testing`
/// package, so that a freshly scaffolded feature has a passing test before it
/// has anything else.
final class _StubRepository implements DeliveryRepository {
  final Map<String, String> records = {};

  @override
  Future<Result<String, DeliveryFailure>> byId(String id) async {
    final found = records[id];
    return found == null
        ? Failed<String, DeliveryFailure>(DeliveryNotFound(id))
        : Success<String, DeliveryFailure>(found);
  }
}
