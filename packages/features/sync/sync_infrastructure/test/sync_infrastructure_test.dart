@Tags(['unit'])
library;

import 'package:sync_infrastructure/sync_infrastructure.dart';
import 'package:test/test.dart';

void main() {
  group('RemoteSyncRepository', () {
    test('reports unavailable until a transport is supplied', () async {
      const repository = RemoteSyncRepository();

      final result = await repository.byId('id');

      expect(result.isFailure, isTrue);
    });

    test('maps a payload without touching a transport', () {
      const repository = RemoteSyncRepository();

      expect(repository.fromPayload({'id': 'value'}), 'value');
    });
  });
}
