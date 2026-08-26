import 'dart:convert';

import 'package:core_kernel/core_kernel.dart';
import 'package:core_testing/core_testing.dart';
import 'package:documents_api/documents_api.dart';
import 'package:documents_core/documents_core.dart';
import 'package:http_dio/http_dio.dart';
import 'package:shipments_api/shipments_api.dart';

/// Everything a documents test needs, wired the way an app would wire it.
final class DocumentsHarness {
  DocumentsHarness({int capacity = 20}) {
    archive = CappedDocumentArchive(store: keyValue, capacity: capacity);
    renderer = HttpDocumentRenderer(transport: http, clock: clock);
    facade = DocumentsCoordinator(
      obtain: ObtainDocument(
        archive: archive,
        renderer: renderer,
        logger: logger,
      ),
    );
  }

  /// The store behind the archive.
  final InMemoryKeyValueStore keyValue = InMemoryKeyValueStore();

  /// The operation's document service.
  final FakeHttpTransport http = FakeHttpTransport();

  /// Time, under the test's control.
  final FakeClock clock = FakeClock(DateTime.utc(2026, 3, 4, 8));

  /// Where a swallowed cache failure is looked for.
  final RecordingLogger logger = RecordingLogger();

  /// The archive under test.
  late final CappedDocumentArchive archive;

  /// The renderer under test.
  late final HttpDocumentRenderer renderer;

  /// The facade under test.
  late final DocumentsCoordinator facade;

  /// Reads a shipment identifier, throwing on an invalid fixture.
  static ShipmentId parcel([String raw = 'SHP-42']) =>
      (ShipmentId.parse(raw) as Success<ShipmentId, ShipmentFailure>).value;

  /// Queues a document the backend will answer with.
  void backendHas({
    String body = 'PDF',
    String mediaType = 'application/pdf',
  }) => http.enqueueJson({
    'mediaType': mediaType,
    'bytes': base64Encode(utf8.encode(body)),
  });

  /// The document behind a successful result.
  static Document valueOf(Result<Document, DocumentsFailure> result) =>
      (result as Success<Document, DocumentsFailure>).value;

  /// The failure behind an unsuccessful one.
  static DocumentsFailure failureOf(
    Result<Document, DocumentsFailure> result,
  ) => (result as Failed<Document, DocumentsFailure>).failure;
}
