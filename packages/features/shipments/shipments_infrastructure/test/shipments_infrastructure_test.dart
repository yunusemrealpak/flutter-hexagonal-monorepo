@Tags(['unit'])
library;

import 'package:shipments_infrastructure/shipments_infrastructure.dart';
import 'package:test/test.dart';

void main() {
  group('RemoteShipmentsRepository', () {
    test('reports unavailable until a transport is supplied', () async {
      const repository = RemoteShipmentsRepository();

      final result = await repository.byId('id');

      expect(result.isFailure, isTrue);
    });

    test('maps a payload without touching a transport', () {
      const repository = RemoteShipmentsRepository();

      expect(repository.fromPayload({'id': 'value'}), 'value');
    });
  });
}
