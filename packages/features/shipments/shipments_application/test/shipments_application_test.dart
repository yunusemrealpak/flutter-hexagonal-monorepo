@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:shipments_api/shipments_api.dart';
import 'package:shipments_application/shipments_application.dart';
import 'package:test/test.dart';

void main() {
  group('LoadShipments', () {
    test('returns what the repository holds', () async {
      final repository = _StubRepository()..records['id'] = 'value';
      final useCase = LoadShipments(repository);

      final result = await useCase('id');

      expect(result.isSuccess, isTrue);
      expect(result.fold((value) => value, (failure) => '$failure'), 'value');
    });

    test('passes a failure through untouched', () async {
      final repository = _StubRepository();
      final useCase = LoadShipments(repository);

      final result = await useCase('missing');

      expect(result.isFailure, isTrue);
    });
  });
}

/// A stub kept local to this file rather than pulled from a `_testing`
/// package, so that a freshly scaffolded feature has a passing test before it
/// has anything else.
final class _StubRepository implements ShipmentsRepository {
  final Map<String, String> records = {};

  @override
  Future<Result<String, ShipmentsFailure>> byId(String id) async {
    final found = records[id];
    return found == null
        ? Failed<String, ShipmentsFailure>(ShipmentsNotFound(id))
        : Success<String, ShipmentsFailure>(found);
  }
}
