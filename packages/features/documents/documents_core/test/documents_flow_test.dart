import 'dart:convert';

import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:documents_api/documents_api.dart';
import 'package:documents_core/documents_core.dart';
import 'package:http_dio/http_dio.dart';
import 'package:test/test.dart';

import 'support/harness.dart';

void main() {
  late DocumentsHarness harness;

  setUp(() => harness = DocumentsHarness());

  group('obtaining a document', () {
    test('produces it and hands back the bytes', () async {
      harness.backendHas(body: 'waybill');

      final document = DocumentsHarness.valueOf(
        await harness.facade.obtain(
          kind: DocumentKind.waybill,
          shipment: DocumentsHarness.parcel(),
        ),
      );

      expect(utf8.decode(document.bytes), 'waybill');
      expect(document.id.value, 'waybill:SHP-42');
      expect(document.renderedAt, harness.clock.now());
    });

    test('the second request is answered from the archive', () async {
      harness.backendHas();
      await harness.facade.obtain(
        kind: DocumentKind.waybill,
        shipment: DocumentsHarness.parcel(),
      );

      final again = await harness.facade.obtain(
        kind: DocumentKind.waybill,
        shipment: DocumentsHarness.parcel(),
      );

      expect(again, isA<Success<Document, DocumentsFailure>>());
      expect(
        harness.http.requests,
        hasLength(1),
        reason: 'the backend was asked once',
      );
    });

    test('refresh produces it again whatever is held', () async {
      harness.backendHas(body: 'old');
      await harness.facade.obtain(
        kind: DocumentKind.waybill,
        shipment: DocumentsHarness.parcel(),
      );
      harness.backendHas(body: 'new');

      final refreshed = DocumentsHarness.valueOf(
        await harness.facade.refresh(
          kind: DocumentKind.waybill,
          shipment: DocumentsHarness.parcel(),
        ),
      );

      expect(utf8.decode(refreshed.bytes), 'new');
      expect(harness.http.requests, hasLength(2));
    });

    test('a refreshed document replaces the one that was held', () async {
      harness.backendHas(body: 'old');
      await harness.facade.obtain(
        kind: DocumentKind.waybill,
        shipment: DocumentsHarness.parcel(),
      );
      harness.backendHas(body: 'new');
      await harness.facade.refresh(
        kind: DocumentKind.waybill,
        shipment: DocumentsHarness.parcel(),
      );

      final held = DocumentsHarness.valueOf(
        await harness.facade.obtain(
          kind: DocumentKind.waybill,
          shipment: DocumentsHarness.parcel(),
        ),
      );

      expect(utf8.decode(held.bytes), 'new');
    });
  });

  group('when the backend says no', () {
    test('a 4xx is a refusal a courier can be told about', () async {
      harness.http.enqueueFailure(
        const TransportRejected(HttpResponse(statusCode: 404)),
      );

      final refused = await harness.facade.obtain(
        kind: DocumentKind.deliveryReceipt,
        shipment: DocumentsHarness.parcel(),
      );

      expect(DocumentsHarness.failureOf(refused), isA<DocumentRefused>());
    });

    test('a 5xx is worth asking again', () async {
      harness.http.enqueueFailure(
        const TransportRejected(HttpResponse(statusCode: 503)),
      );

      final failed = await harness.facade.obtain(
        kind: DocumentKind.waybill,
        shipment: DocumentsHarness.parcel(),
      );

      expect(DocumentsHarness.failureOf(failed), isA<RenderFailed>());
    });

    test('so is no connection at all', () async {
      harness.http.enqueueFailure(const TransportOffline());

      final failed = await harness.facade.obtain(
        kind: DocumentKind.waybill,
        shipment: DocumentsHarness.parcel(),
      );

      expect(DocumentsHarness.failureOf(failed), isA<RenderFailed>());
    });

    test('a body with no document in it is a render failure', () async {
      harness.http.enqueueJson({'mediaType': 'application/pdf'});

      final failed = await harness.facade.obtain(
        kind: DocumentKind.waybill,
        shipment: DocumentsHarness.parcel(),
      );

      expect(DocumentsHarness.failureOf(failed), isA<RenderFailed>());
    });

    test('an empty document is refused rather than shown blank', () async {
      harness.backendHas(body: '');

      final failed = await harness.facade.obtain(
        kind: DocumentKind.waybill,
        shipment: DocumentsHarness.parcel(),
      );

      expect(DocumentsHarness.failureOf(failed), isA<MalformedDocument>());
    });
  });

  group('when the archive misbehaves', () {
    test('a read failure is logged and the document still arrives', () async {
      harness.keyValue.failNextWith(const StoreUnavailable(detail: 'locked'));
      harness.backendHas();

      final document = await harness.facade.obtain(
        kind: DocumentKind.waybill,
        shipment: DocumentsHarness.parcel(),
      );

      expect(document, isA<Success<Document, DocumentsFailure>>());
      expect(harness.logger.recordsAt(LogLevel.warning), isNotEmpty);
    });

    test('a write failure does not fail the answer', () async {
      harness.backendHas();
      harness.keyValue
        ..failNextWith(const StoreUnavailable())
        ..failNextWith(const StoreOutOfSpace());

      final document = await harness.facade.obtain(
        kind: DocumentKind.waybill,
        shipment: DocumentsHarness.parcel(),
      );

      expect(document, isA<Success<Document, DocumentsFailure>>());
    });

    test('a corrupt archive is treated as an empty one', () async {
      await harness.keyValue.write(CappedDocumentArchive.key, 'not json');
      harness.backendHas();

      final document = await harness.facade.obtain(
        kind: DocumentKind.waybill,
        shipment: DocumentsHarness.parcel(),
      );

      expect(document, isA<Success<Document, DocumentsFailure>>());
    });
  });

  group('the cap', () {
    test('keeps the newest and drops the oldest', () async {
      harness = DocumentsHarness(capacity: 2);
      for (final id in ['SHP-1', 'SHP-2', 'SHP-3']) {
        harness.backendHas(body: id);
        await harness.facade.obtain(
          kind: DocumentKind.waybill,
          shipment: DocumentsHarness.parcel(id),
        );
        harness.clock.advance(const Duration(minutes: 1));
      }

      final oldest = await harness.archive.read('waybill:SHP-1');
      final newest = await harness.archive.read('waybill:SHP-3');

      expect(DocumentsHarness.failureOf(oldest), isA<DocumentMissing>());
      expect(newest, isA<Success<Document, DocumentsFailure>>());
    });

    test('an evicted document is produced again on request', () async {
      harness = DocumentsHarness(capacity: 1)..backendHas(body: 'first');
      await harness.facade.obtain(
        kind: DocumentKind.waybill,
        shipment: DocumentsHarness.parcel('SHP-1'),
      );
      harness.clock.advance(const Duration(minutes: 1));
      harness.backendHas(body: 'second');
      await harness.facade.obtain(
        kind: DocumentKind.waybill,
        shipment: DocumentsHarness.parcel('SHP-2'),
      );

      harness.backendHas(body: 'first again');
      final again = DocumentsHarness.valueOf(
        await harness.facade.obtain(
          kind: DocumentKind.waybill,
          shipment: DocumentsHarness.parcel('SHP-1'),
        ),
      );

      expect(utf8.decode(again.bytes), 'first again');
    });
  });
}
