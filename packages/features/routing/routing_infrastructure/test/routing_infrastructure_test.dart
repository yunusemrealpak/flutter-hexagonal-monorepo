@Tags(['unit'])
library;

import 'package:routing_infrastructure/routing_infrastructure.dart';
import 'package:test/test.dart';

void main() {
  group('RemoteRoutingRepository', () {
    test('reports unavailable until a transport is supplied', () async {
      const repository = RemoteRoutingRepository();

      final result = await repository.byId('id');

      expect(result.isFailure, isTrue);
    });

    test('maps a payload without touching a transport', () {
      const repository = RemoteRoutingRepository();

      expect(repository.fromPayload({'id': 'value'}), 'value');
    });
  });
}
