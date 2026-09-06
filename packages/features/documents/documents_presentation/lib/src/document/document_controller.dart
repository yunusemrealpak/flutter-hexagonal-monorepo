import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:documents_api/documents_api.dart';
import 'package:flutter/foundation.dart';
import 'package:shipments_api/shipments_api.dart';

import 'document_state.dart';

/// How an app hands a document to the platform's share sheet.
///
/// A callback, not a port, and that is the same decision
/// `delivery_presentation` made about the camera in phase 5: a presentation
/// package may not depend on `platform/*`, and sharing has no `platform/*`
/// package behind it yet. The app supplies a function; this package calls it
/// and knows nothing about what happens next.
typedef ShareDocument = Future<void> Function(Document document);

/// Drives the document screen.
///
/// It holds one port — `DocumentsFacade` — and one callback. Whether the
/// document came from the archive or from the server is something this package
/// cannot see, and does not need to.
final class DocumentController extends ChangeNotifier {
  /// Creates the controller for one piece of paperwork.
  DocumentController({
    required this._documents,
    required this._kind,
    required this._shipment,
    this._share,
  });

  final DocumentsFacade _documents;
  final DocumentKind _kind;
  final ShipmentId _shipment;
  final ShareDocument? _share;

  DocumentState _state = const DocumentIdle();

  /// What the screen should be showing.
  DocumentState get state => _state;

  /// Whether this app can share at all.
  ///
  /// An app that supplied no callback — a dispatcher's web build, say — gets a
  /// screen with no share control rather than one that does nothing when
  /// pressed.
  bool get canShare => _share != null;

  /// Obtains the document, from the archive if it is there.
  Future<void> load() => _obtain(_documents.obtain);

  /// Produces the document again, whatever is held.
  Future<void> refresh() => _obtain(_documents.refresh);

  /// Hands the document to the app's share sheet.
  ///
  /// Does nothing unless a document is on screen. Sharing what a person cannot
  /// see is how somebody sends the wrong waybill to a customer.
  Future<void> share() async {
    final share = _share;
    if (share == null) {
      return;
    }
    if (_state case DocumentReady(:final document)) {
      await share(document);
    }
  }

  Future<void> _obtain(
    Future<Result<Document, DocumentsFailure>> Function({
      required DocumentKind kind,
      required ShipmentId shipment,
    })
    obtain,
  ) async {
    _emit(const DocumentLoading());

    final obtained = await obtain(kind: _kind, shipment: _shipment);
    _emit(
      switch (obtained) {
        Success(:final value) => DocumentReady(value),
        Failed(:final failure) => DocumentFailed(failure),
      },
    );
  }

  void _emit(DocumentState next) {
    _state = next;
    notifyListeners();
  }
}
