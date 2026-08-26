import 'package:core_kernel/core_kernel.dart';
import 'package:documents_api/documents_api.dart';
import 'package:shipments_api/shipments_api.dart';
import 'package:test/test.dart';

final DateTime rendered = DateTime.utc(2026, 3, 4, 8);

ShipmentId get parcel =>
    (ShipmentId.parse('SHP-42') as Success<ShipmentId, ShipmentFailure>).value;

Document document({
  DocumentKind kind = DocumentKind.waybill,
  List<int> bytes = const [37, 80, 68, 70],
  DateTime? at,
}) =>
    (Document.rendered(
              kind: kind,
              shipment: parcel,
              mediaType: 'application/pdf',
              bytes: bytes,
              renderedAt: at ?? rendered,
            )
            as Success<Document, DocumentsFailure>)
        .value;

void main() {
  group('a rendered document', () {
    test('takes its identifier from the kind and the parcel', () {
      expect(document().id.value, 'waybill:SHP-42');
    });

    test('knows how big it is and when it was made', () {
      final one = document();

      expect(one.sizeInBytes, 4);
      expect(one.renderedAt, rendered);
    });

    test('refuses empty bytes', () {
      expect(
        Document.rendered(
          kind: DocumentKind.waybill,
          shipment: parcel,
          mediaType: 'application/pdf',
          bytes: const [],
          renderedAt: rendered,
        ),
        isA<Failed<Document, DocumentsFailure>>(),
      );
    });

    test('refuses an empty media type', () {
      expect(
        Document.rendered(
          kind: DocumentKind.waybill,
          shipment: parcel,
          mediaType: '  ',
          bytes: const [1],
          renderedAt: rendered,
        ),
        isA<Failed<Document, DocumentsFailure>>(),
      );
    });

    test('cannot have its bytes changed from outside', () {
      expect(() => document().bytes.add(0), throwsUnsupportedError);
    });

    test('two renders of one document are the same document', () {
      expect(
        document(),
        document(at: rendered.add(const Duration(days: 1))),
      );
    });

    test('two kinds for one parcel are different documents', () {
      expect(
        document(),
        isNot(document(kind: DocumentKind.deliveryReceipt)),
      );
    });

    test('says whether it predates an instant', () {
      expect(
        document().renderedBefore(rendered.add(const Duration(days: 1))),
        isTrue,
      );
      expect(document().renderedBefore(rendered), isFalse);
    });
  });

  group('DocumentId', () {
    test('round-trips every kind through parse', () {
      for (final kind in DocumentKind.values) {
        final id = DocumentId.of(kind: kind, shipment: parcel);

        expect(
          (DocumentId.parse(id.value) as Success<DocumentId, DocumentsFailure>)
              .value,
          id,
        );
      }
    });

    test('refuses an identifier that is not a kind and a shipment', () {
      for (final raw in ['waybill', 'waybill:', ':SHP-42', 'invoice:SHP-42']) {
        expect(
          DocumentId.parse(raw),
          isA<Failed<DocumentId, DocumentsFailure>>(),
          reason: raw,
        );
      }
    });
  });
}
