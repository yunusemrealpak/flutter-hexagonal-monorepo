@Tags(['unit'])
library;

import 'package:delivery_infrastructure/delivery_infrastructure.dart';
import 'package:test/test.dart';

void main() {
  group('RemoteDeliveryRepository', () {
    test('reports unavailable until a transport is supplied', () async {
      const repository = RemoteDeliveryRepository();

      final result = await repository.byId('id');

      expect(result.isFailure, isTrue);
    });

    test('maps a payload without touching a transport', () {
      const repository = RemoteDeliveryRepository();

      expect(repository.fromPayload({'id': 'value'}), 'value');
    });
  });
}
