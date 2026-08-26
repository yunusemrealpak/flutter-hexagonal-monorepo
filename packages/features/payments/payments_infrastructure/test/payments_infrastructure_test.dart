@Tags(['unit'])
library;

import 'package:payments_infrastructure/payments_infrastructure.dart';
import 'package:test/test.dart';

void main() {
  group('RemotePaymentsRepository', () {
    test('reports unavailable until a transport is supplied', () async {
      const repository = RemotePaymentsRepository();

      final result = await repository.byId('id');

      expect(result.isFailure, isTrue);
    });

    test('maps a payload without touching a transport', () {
      const repository = RemotePaymentsRepository();

      expect(repository.fromPayload({'id': 'value'}), 'value');
    });
  });
}
