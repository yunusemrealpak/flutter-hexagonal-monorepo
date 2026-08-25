@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';
import 'package:identity_application/identity_application.dart';
import 'package:test/test.dart';

void main() {
  group('LoadIdentity', () {
    test('returns what the repository holds', () async {
      final repository = _StubRepository()..records['id'] = 'value';
      final useCase = LoadIdentity(repository);

      final result = await useCase('id');

      expect(result.isSuccess, isTrue);
      expect(result.fold((value) => value, (failure) => '$failure'), 'value');
    });

    test('passes a failure through untouched', () async {
      final repository = _StubRepository();
      final useCase = LoadIdentity(repository);

      final result = await useCase('missing');

      expect(result.isFailure, isTrue);
    });
  });
}

/// A stub kept local to this file rather than pulled from a `_testing`
/// package, so that a freshly scaffolded feature has a passing test before it
/// has anything else.
final class _StubRepository implements IdentityRepository {
  final Map<String, String> records = {};

  @override
  Future<Result<String, IdentityFailure>> byId(String id) async {
    final found = records[id];
    return found == null
        ? Failed<String, IdentityFailure>(IdentityNotFound(id))
        : Success<String, IdentityFailure>(found);
  }
}
