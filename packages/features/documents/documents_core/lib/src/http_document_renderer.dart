import 'dart:convert';

import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:documents_api/documents_api.dart';
import 'package:http_dio/http_dio.dart';
import 'package:shipments_api/shipments_api.dart';

/// Asks the operation's backend to produce a document.
///
/// **The rendering happens on the server, and that is a decision rather than
/// a shortcut.** A waybill is a legal document whose layout changes when the
/// operation's terms do; rendering it on a phone would mean every courier
/// carrying a version of the template, and a fleet updating over weeks would
/// produce weeks of documents that disagree.
///
/// The bytes come back base64-encoded inside JSON, because `HttpTransport`
/// answers with a decoded body rather than a stream. That is the transport's
/// shape and this adapter's problem: it decodes once, and nothing else in the
/// feature knows.
final class HttpDocumentRenderer implements DocumentRenderer {
  /// Creates the adapter over the transport and the clock it stamps with.
  const HttpDocumentRenderer({required this._transport, required this._clock});

  final HttpTransport _transport;
  final Clock _clock;

  @override
  Future<Result<Document, DocumentsFailure>> render({
    required DocumentKind kind,
    required String shipmentId,
  }) async {
    final response = await _transport.send(
      HttpRequest(
        method: HttpMethod.get,
        path: '/shipments/$shipmentId/documents/${kind.name}',
      ),
    );

    return switch (response) {
      Failed(:final failure) => Failed(_translate(failure)),
      Success(:final value) => _read(kind, shipmentId, value.body),
    };
  }

  /// Builds the document out of whatever came back.
  ///
  /// This is the one place in the feature that rebuilds a `ShipmentId` — the
  /// port took a string and `Document` names the type — and it is why a
  /// malformed identifier is a `RenderFailed` rather than a
  /// `MalformedDocument`: the identifier came from *this device*, so a server
  /// that echoed something else back is a server fault.
  Result<Document, DocumentsFailure> _read(
    DocumentKind kind,
    String shipmentId,
    Object? body,
  ) {
    if (body is! Map<String, Object?>) {
      return const Failed(
        RenderFailed(detail: 'the response was not a document'),
      );
    }

    final mediaType = body['mediaType'];
    final encoded = body['bytes'];
    if (mediaType is! String || encoded is! String) {
      return const Failed(
        RenderFailed(detail: 'the response carried no document'),
      );
    }

    final List<int> bytes;
    try {
      bytes = base64Decode(encoded);
    } on FormatException {
      return const Failed(
        RenderFailed(detail: 'the document was not readable'),
      );
    }

    final shipment = ShipmentId.parse(shipmentId);
    if (shipment case Failed()) {
      return const Failed(
        RenderFailed(detail: 'the response named another parcel'),
      );
    }

    return Document.rendered(
      kind: kind,
      shipment: (shipment as Success<ShipmentId, ShipmentFailure>).value,
      mediaType: mediaType,
      bytes: bytes,
      renderedAt: _clock.now(),
    );
  }

  /// Sorts what is worth asking again from what is not.
  ///
  /// A 4xx is the operation saying this document does not exist and will not —
  /// a receipt for a delivery that has not happened — and a courier deserves
  /// that sentence rather than a spinner. Everything else is worth a retry.
  DocumentsFailure _translate(TransportFailure failure) => switch (failure) {
    TransportRejected(:final statusCode) when statusCode < 500 =>
      DocumentRefused(
        reason: 'the operation will not produce it ($statusCode)',
      ),
    _ => RenderFailed(detail: failure.toString()),
  };
}
