import 'package:core_kernel/core_kernel.dart';
import 'package:http_dio/http_dio.dart';
import 'package:shipments_api/shipments_api.dart';

import 'shipment_dto.dart';

/// Answers the domain's contract using one technology, and lets no exception
/// out: the failure branch is the return type, not a throw.
final class HttpShipmentRepository implements ShipmentRepository {
  /// Creates the adapter.
  const HttpShipmentRepository(this._transport);

  final HttpTransport _transport;

  @override
  Future<Result<String, Object>> byId(String id) async {
    final body = await _transport.get('/shipments/$id');
    if (body == null) return const Failed('not found');
    return Success(ShipmentDto.fromJson(body).id);
  }
}
