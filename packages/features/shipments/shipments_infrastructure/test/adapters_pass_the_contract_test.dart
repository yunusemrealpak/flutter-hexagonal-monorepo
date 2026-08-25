@Tags(['unit'])
library;

import 'dart:convert';

import 'package:core_kernel/core_kernel.dart';
import 'package:core_testing/core_testing.dart';
import 'package:http_dio/http_dio.dart';
import 'package:shipments_infrastructure/shipments_infrastructure.dart';
import 'package:shipments_testing/shipments_testing.dart';
import 'package:test/test.dart';

/// A transport that behaves like the operation's API, in memory.
///
/// `FakeHttpTransport` in `http_dio` answers from a queue, which is right for
/// asserting what a single call does and useless for running a suite that
/// saves and then reads back. This one routes, so the contract kit can seed
/// through `save` exactly as it does against the in-memory gateway.
///
/// It lives in this test file rather than in `http_dio` on purpose: it knows
/// the shipments API's paths, and a platform package that knew a feature's
/// endpoints would have stopped being a platform package.
final class _ShipmentsApiTransport implements HttpTransport {
  final Map<String, Map<String, dynamic>> _shipments = {};

  @override
  Future<Result<HttpResponse, TransportFailure>> send(
    HttpRequest request,
  ) async {
    final path = request.path;

    if (request.method == HttpMethod.put && path.startsWith('/shipments/')) {
      final id = path.substring('/shipments/'.length);
      final body = jsonDecode(request.body! as String) as Map<String, dynamic>;
      _shipments[id] = body;
      return Success(HttpResponse(statusCode: 200, body: jsonEncode(body)));
    }

    if (request.method == HttpMethod.get && path.startsWith('/shipments/')) {
      final id = path.substring('/shipments/'.length);
      final stored = _shipments[id];
      if (stored == null) {
        return const Failed(
          TransportRejected(HttpResponse(statusCode: 404)),
        );
      }
      return Success(HttpResponse(statusCode: 200, body: jsonEncode(stored)));
    }

    if (request.method == HttpMethod.get && path.startsWith('/barcodes/')) {
      final barcode = path.substring('/barcodes/'.length);
      for (final entry in _shipments.entries) {
        if (entry.value['barcode'] == barcode) {
          return Success(
            HttpResponse(statusCode: 200, body: jsonEncode({'id': entry.key})),
          );
        }
      }
      return const Failed(TransportRejected(HttpResponse(statusCode: 404)));
    }

    if (request.method == HttpMethod.get && path == '/manifests') {
      final courier = request.query['courier'];
      final rows = _shipments.values
          .where(
            (shipment) =>
                (shipment['status'] as Map<String, dynamic>?)?['courier'] ==
                courier,
          )
          .map(
            (shipment) => {
              'id': shipment['id'],
              'barcode': shipment['barcode'],
              'status': shipment['status'],
              'consigneeName':
                  (shipment['consignee'] as Map<String, dynamic>?)?['name'],
              'address':
                  ((shipment['consignee'] as Map<String, dynamic>?)?['address']
                      as Map<String, dynamic>?)?['formatted'],
            },
          )
          .toList();
      return Success(
        HttpResponse(statusCode: 200, body: jsonEncode(rows)),
      );
    }

    return const Success(HttpResponse(statusCode: 404));
  }
}

void main() {
  // The whole point of the contract kit. The same two suites that run against
  // the in-memory fakes in shipments_testing run here against the adapters
  // that actually ship — so a fake and the thing it stands in for cannot drift
  // apart without one of the two runs going red.
  runShipmentGatewayContract(
    () => RestShipmentGateway(transport: _ShipmentsApiTransport()),
  );

  runShipmentCacheContract(
    () => KeyValueShipmentCache(store: InMemoryKeyValueStore()),
  );
}
