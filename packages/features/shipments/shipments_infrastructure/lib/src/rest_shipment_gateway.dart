import 'dart:convert';

import 'package:core_kernel/core_kernel.dart';
import 'package:http_dio/http_dio.dart';
import 'package:shipments_api/shipments_api.dart';

import 'shipment_dto.dart';
import 'shipment_mapper.dart';

/// Answers `ShipmentGateway` over the operation's REST API.
///
/// Everything protocol-shaped stops here. The use case above it asked for a
/// shipment; this class decides that the question is a `GET /shipments/{id}`,
/// that a 404 means `ShipmentNotFound` and a timeout means
/// `ShipmentsUnavailable`, and that the body has to go through a DTO and a
/// mapper before anything upstairs sees it.
///
/// It takes an `HttpTransport` rather than a `Dio`. That contract lives in
/// `platform/http_dio` together with its adapter and its fake, so this class
/// never opens a socket in a test and the day Dio is replaced, one file in one
/// platform package changes.
///
/// No method throws. Every path out returns a `Result` with a
/// `ShipmentFailure`, which is invariant 1.2.9 at the place it is easiest to
/// break: an adapter is where the exceptions actually come from.
final class RestShipmentGateway implements ShipmentGateway {
  /// Creates the adapter over [transport].
  const RestShipmentGateway({required this.transport});

  /// The transport requests are sent on.
  final HttpTransport transport;

  @override
  Future<Result<Shipment, ShipmentFailure>> byId(ShipmentId id) async {
    final response = await transport.send(
      HttpRequest(method: HttpMethod.get, path: '/shipments/${id.value}'),
    );

    return switch (response) {
      Failed(:final failure) => Failed(_translate(failure, id: id)),
      Success(value: final ok) => _decodeShipment(ok.body),
    };
  }

  @override
  Future<Result<List<ShipmentSummary>, ShipmentFailure>> manifestFor(
    String courierId,
  ) async {
    final response = await transport.send(
      HttpRequest(
        method: HttpMethod.get,
        path: '/manifests',
        query: {'courier': courierId},
      ),
    );

    return switch (response) {
      Failed(:final failure) => Failed(_translate(failure)),
      Success(value: final ok) => _decodeManifest(ok.body),
    };
  }

  @override
  Future<Result<Shipment, ShipmentFailure>> save(Shipment shipment) async {
    final response = await transport.send(
      HttpRequest(
        method: HttpMethod.put,
        path: '/shipments/${shipment.id.value}',
        body: jsonEncode(ShipmentMapper.toDto(shipment).toJson()),
      ),
    );

    return switch (response) {
      Failed(:final failure) => Failed(_translate(failure, id: shipment.id)),
      // The stored shipment is read back from the response rather than assumed
      // to equal what was sent. The far side is entitled to normalise, and an
      // adapter that returned its own input would hide that until two devices
      // disagreed.
      Success(value: final ok) => _decodeShipment(ok.body),
    };
  }

  @override
  Future<Result<ShipmentId, ShipmentFailure>> resolve(Barcode barcode) async {
    final response = await transport.send(
      HttpRequest(
        method: HttpMethod.get,
        path: '/barcodes/${barcode.value}',
      ),
    );

    return switch (response) {
      Failed(failure: TransportRejected(statusCode: 404)) => Failed(
        BarcodeNotRecognised(barcode.value),
      ),
      Failed(:final failure) => Failed(_translate(failure)),
      Success(value: final ok) => _decodeId(ok.body, barcode),
    };
  }

  Result<Shipment, ShipmentFailure> _decodeShipment(Object? body) {
    final json = _asMap(body);
    if (json == null) {
      return const Failed(
        MalformedValue(field: 'body', reason: 'is not a JSON object'),
      );
    }
    return ShipmentMapper.toDomain(ShipmentDto.fromJson(json));
  }

  Result<List<ShipmentSummary>, ShipmentFailure> _decodeManifest(Object? body) {
    final decoded = body is String ? _tryDecode(body) : body;
    if (decoded is! List) {
      return const Failed(
        MalformedValue(field: 'body', reason: 'is not a JSON array'),
      );
    }

    final rows = <ShipmentSummary>[];
    for (final entry in decoded) {
      final json = _asMap(entry);
      if (json == null) {
        return const Failed(
          MalformedValue(field: 'body', reason: 'a row is not a JSON object'),
        );
      }
      final row = ShipmentMapper.summaryToDomain(
        ShipmentSummaryDto.fromJson(json),
      );
      // One bad row fails the whole manifest rather than being skipped. A
      // stop list that quietly omits a parcel is a parcel nobody delivers, and
      // nobody finds out until the depot counts.
      switch (row) {
        case Failed(:final failure):
          return Failed(failure);
        case Success(:final value):
          rows.add(value);
      }
    }
    return Success(rows);
  }

  Result<ShipmentId, ShipmentFailure> _decodeId(Object? body, Barcode barcode) {
    final json = _asMap(body);
    final id = json?['id'];
    if (id is! String) {
      return Failed(BarcodeNotRecognised(barcode.value));
    }
    return ShipmentId.parse(id);
  }

  static Map<String, dynamic>? _asMap(Object? body) {
    final decoded = body is String ? _tryDecode(body) : body;
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  static Object? _tryDecode(String raw) {
    // The one place this package catches. A body that is not JSON is the far
    // side's mistake, and the only alternative to catching here is letting a
    // FormatException cross a port boundary — which invariant 1.2.9 forbids
    // and which would reach a use case that has no way to handle it.
    try {
      return jsonDecode(raw);
    } on FormatException {
      return null;
    }
  }

  /// Turns a transport failure into the vocabulary the port promises.
  ///
  /// This is the whole reason the two failure hierarchies are separate. A
  /// caller of `ShipmentGateway` handles `ShipmentFailure` and must never see
  /// a `TransportRejected`: the status code is a fact about HTTP, and a use
  /// case that switched on it would be a use case that stops compiling when
  /// the API moves to gRPC.
  static ShipmentFailure _translate(
    TransportFailure failure, {
    ShipmentId? id,
  }) => switch (failure) {
    TransportRejected(statusCode: 404) when id != null => ShipmentNotFound(id),
    TransportRejected(:final statusCode) => ShipmentsUnavailable(
      detail: 'rejected with $statusCode',
    ),
    TransportOffline(:final detail) => ShipmentsUnavailable(detail: detail),
    TransportTimeout(:final phase) => ShipmentsUnavailable(
      detail: 'timed out while ${phase.name}ing',
    ),
    TransportCancelled() => const ShipmentsUnavailable(detail: 'cancelled'),
    TransportCertificateRejected() => const ShipmentsUnavailable(
      detail: 'certificate rejected',
    ),
    TransportUnexpected(:final detail) => ShipmentsUnavailable(detail: detail),
  };
}
