@Tags(['widget'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:design_system/design_system.dart';
import 'package:documents_api/documents_api.dart';
import 'package:documents_presentation/documents_presentation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shipments_api/shipments_api.dart';

ShipmentId get _parcel =>
    (ShipmentId.parse('SHP-42') as Success<ShipmentId, ShipmentFailure>).value;

/// A `DocumentsFacade` this test steers.
final class _Documents implements DocumentsFacade {
  int renders = 0;

  /// Set to fail the next call, whatever it is.
  DocumentsFailure? failWith;

  /// What the next render produces.
  List<int> bytes = const [37, 80, 68, 70];

  @override
  Future<Result<Document, DocumentsFailure>> obtain({
    required DocumentKind kind,
    required ShipmentId shipment,
  }) async => _produce(kind, shipment);

  @override
  Future<Result<Document, DocumentsFailure>> refresh({
    required DocumentKind kind,
    required ShipmentId shipment,
  }) async => _produce(kind, shipment);

  Result<Document, DocumentsFailure> _produce(
    DocumentKind kind,
    ShipmentId shipment,
  ) {
    final failure = failWith;
    if (failure != null) {
      failWith = null;
      return Failed(failure);
    }
    renders++;
    return Document.rendered(
      kind: kind,
      shipment: shipment,
      mediaType: 'application/pdf',
      bytes: bytes,
      renderedAt: DateTime.utc(2026, 3, 4, 8),
    );
  }
}

Widget _wrap(Widget child) => PeykTheme.wrap(child: child);

void main() {
  late _Documents documents;

  setUp(() => documents = _Documents());

  DocumentController controller({ShareDocument? share}) {
    final built = DocumentController(
      documents: documents,
      kind: DocumentKind.waybill,
      shipment: _parcel,
      share: share,
    );
    addTearDown(built.dispose);
    return built;
  }

  testWidgets('a document shows its kind and its size', (tester) async {
    await tester.pumpWidget(_wrap(DocumentScreen(controller: controller())));
    await tester.pumpAndSettle();

    expect(
      find.text(DocumentsStrings.kind(DocumentKind.waybill)),
      findsOneWidget,
    );
    // A key with the byte count in it, not a formatted size: "1.2 MB" and
    // "1,2 MB" are the same number written two ways, and only the app knows
    // which is right.
    expect(find.text('${DocumentsStrings.size}(bytes=4)'), findsOneWidget);
  });

  testWidgets('an app with no share callback shows no share control', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(DocumentScreen(controller: controller())));
    await tester.pumpAndSettle();

    expect(find.text(DocumentsStrings.share), findsNothing);
  });

  testWidgets('an app that can share gets the control, and it works', (
    tester,
  ) async {
    final shared = <Document>[];
    final subject = controller(share: (document) async => shared.add(document));

    await tester.pumpWidget(_wrap(DocumentScreen(controller: subject)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(DocumentsStrings.share));
    await tester.pumpAndSettle();

    expect(shared, hasLength(1));
    expect(shared.single.kind, DocumentKind.waybill);
  });

  testWidgets('a refusal is a different sentence from a failure', (
    tester,
  ) async {
    documents.failWith = const DocumentRefused(reason: 'not delivered yet');

    await tester.pumpWidget(_wrap(DocumentScreen(controller: controller())));
    await tester.pumpAndSettle();

    expect(
      find.text(
        '${DocumentsStrings.failureRefused}(reason=not delivered yet)',
      ),
      findsOneWidget,
    );
  });

  test('sharing before the document arrives does nothing', () async {
    final shared = <Document>[];
    final subject = controller(share: (document) async => shared.add(document));

    await subject.share();

    expect(shared, isEmpty);
  });

  test('refresh asks for the document again', () async {
    final subject = controller();
    await subject.load();

    await subject.refresh();

    expect(documents.renders, 2);
    expect(subject.state, isA<DocumentReady>());
  });

  group('what DocumentsStrings.all covers', () {
    test('every kind and every failure has a key in it', () {
      for (final kind in DocumentKind.values) {
        expect(DocumentsStrings.all, contains(DocumentsStrings.kind(kind)));
      }
      const failures = <DocumentsFailure>[
        RenderFailed(),
        DocumentRefused(reason: 'not delivered yet'),
        ArchiveUnavailable(),
        DocumentMissing('doc-1'),
        MalformedDocument(field: 'kind', reason: 'unreadable'),
      ];
      for (final failure in failures) {
        expect(
          DocumentsStrings.all,
          contains(DocumentScreen.describe(failure)),
        );
      }
    });

    // A refusal is the operation's decision. Asking twice gets the same answer
    // with a longer wait, so the button is absent rather than useless.
    test('only a refusal offers no retry', () {
      expect(
        DocumentScreen.canRetry(const DocumentRefused(reason: 'no')),
        isFalse,
      );
      expect(DocumentScreen.canRetry(const RenderFailed()), isTrue);
      expect(DocumentScreen.canRetry(const ArchiveUnavailable()), isTrue);
    });
  });
}
