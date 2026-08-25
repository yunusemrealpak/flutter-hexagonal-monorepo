@Tags(['unit'])
library;

import 'package:identity_infrastructure/identity_infrastructure.dart';
import 'package:test/test.dart';

void main() {
  group('RemoteIdentityRepository', () {
    test('reports unavailable until a transport is supplied', () async {
      const repository = RemoteIdentityRepository();

      final result = await repository.byId('id');

      expect(result.isFailure, isTrue);
    });

    test('maps a payload without touching a transport', () {
      const repository = RemoteIdentityRepository();

      expect(repository.fromPayload({'id': 'value'}), 'value');
    });
  });
}
