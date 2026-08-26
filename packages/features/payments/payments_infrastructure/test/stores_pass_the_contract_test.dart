@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:core_testing/core_testing.dart';
import 'package:http_dio/http_dio.dart';
import 'package:payments_infrastructure/payments_infrastructure.dart';
import 'package:payments_testing/payments_testing.dart';
import 'package:test/test.dart';

/// A stand-in for the operation's payments service.
///
/// `FakeHttpTransport` answers from a queue, which is right for a test that
/// scripts one exchange and wrong for a contract kit: the kit collects, then
/// reads back what it collected, and the second answer depends on the first.
/// So this transport keeps a map — it is a fake *server*, not a fake adapter,
/// and `RestPaymentsGateway` is the thing under test either way.
///
/// It implements the same idempotency the port demands, because that is what a
/// real server does and the kit is checking that the *adapter* carries the key
/// correctly rather than that the server is honest.
final class _PaymentsServer implements HttpTransport {
  final Map<String, Object?> _byKey = {};
  final Map<String, String> _keyByShipment = {};

  @override
  Future<Result<HttpResponse, TransportFailure>> send(
    HttpRequest request,
  ) async {
    final segments = request.path.split('/')..removeWhere((s) => s.isEmpty);

    if (request.method == HttpMethod.put) {
      final key = segments.last;
      final body = request.body! as Map<String, dynamic>;

      // Money moves once: a key whose outcome is already final answers with
      // what it has. Anything else carries the intention forward.
      final stored = _byKey[key];
      if (stored is Map<String, dynamic> &&
          (stored['outcome'] == 'taken' || stored['outcome'] == 'refunded')) {
        return Success(HttpResponse(statusCode: 200, body: stored));
      }

      _byKey[key] = body;
      _keyByShipment['${body['shipmentId']}'] = key;
      return Success(HttpResponse(statusCode: 200, body: body));
    }

    if (request.method == HttpMethod.post) {
      final key = segments[segments.length - 2];
      final stored = _byKey[key];
      if (stored is! Map<String, dynamic>) {
        return const Failed(
          TransportRejected(HttpResponse(statusCode: 404)),
        );
      }
      if (stored['outcome'] == 'refunded') {
        return Success(HttpResponse(statusCode: 200, body: stored));
      }
      final refunded = {
        ...stored,
        'outcome': 'refunded',
        'refundedAt': PaymentsFixtures.noon.toIso8601String(),
      };
      _byKey[key] = refunded;
      return Success(HttpResponse(statusCode: 200, body: refunded));
    }

    final key = _keyByShipment[request.query['shipmentId']];
    return Success(HttpResponse(statusCode: 200, body: _byKey[key]));
  }
}

void main() {
  // One description, three answers: the fake in payments_testing, the REST
  // adapter, and the REST adapter behind the device-backed decorator. That the
  // decorator changes nothing the kit can see is the assertion that matters —
  // it adds an offline answer, not a different contract.
  group('RestPaymentsGateway', () {
    runPaymentsGatewayContract(
      () => RestPaymentsGateway(transport: _PaymentsServer()),
    );
  });

  group('DeviceBackedPaymentsGateway over REST', () {
    runPaymentsGatewayContract(
      () => DeviceBackedPaymentsGateway(
        remote: RestPaymentsGateway(transport: _PaymentsServer()),
        store: InMemoryKeyValueStore(),
      ),
    );
  });

  group('KeyValueSettlementStore', () {
    runSettlementStoreContract(
      () => KeyValueSettlementStore(store: InMemoryKeyValueStore()),
    );
  });
}
