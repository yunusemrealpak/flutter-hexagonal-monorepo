import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core_kernel/core_kernel.dart';
import 'package:documents_api/documents_api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipments_api/shipments_api.dart';

import 'document_event.dart';
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
///
/// **Both requests are `droppable()`, and neither is `restartable()`.**
/// Restarting would cancel a render that is already running and ask for the
/// same one again, which on this port means paying for the work twice — a
/// document is produced server-side, not read from a list. Dropping a repeated
/// tap is what a person pressing *retry* twice actually means.
///
/// **`DocumentShared` emits nothing.** It reads the document off the current
/// state and hands it over, which is a side effect rather than a transition:
/// nothing about the screen changes because somebody shared what is on it.
final class DocumentBloc extends Bloc<DocumentEvent, DocumentState> {
  /// Creates the bloc for one piece of paperwork.
  DocumentBloc({
    required this._documents,
    required this._kind,
    required this._shipment,
    this._share,
  }) : super(const DocumentIdle()) {
    on<DocumentRequested>(
      (event, emit) => _obtain(_documents.obtain, emit),
      transformer: droppable(),
    );
    on<DocumentRefreshRequested>(
      (event, emit) => _obtain(_documents.refresh, emit),
      transformer: droppable(),
    );
    on<DocumentShared>(_onShared);
  }

  final DocumentsFacade _documents;
  final DocumentKind _kind;
  final ShipmentId _shipment;
  final ShareDocument? _share;

  /// Whether this app can share at all.
  ///
  /// An app that supplied no callback — a dispatcher's web build, say — gets a
  /// screen with no share control rather than one that does nothing when
  /// pressed. Read from the bloc rather than carried in the state, because it
  /// is a fact about the app and not about the document.
  bool get canShare => _share != null;

  /// Hands the document to the app's share sheet.
  ///
  /// Does nothing unless a document is on screen. Sharing what a person cannot
  /// see is how somebody sends the wrong waybill to a customer.
  Future<void> _onShared(
    DocumentShared event,
    Emitter<DocumentState> emit,
  ) async {
    final share = _share;
    if (share == null) return;
    if (state case DocumentReady(:final document)) {
      await share(document);
    }
  }

  Future<void> _obtain(
    Future<Result<Document, DocumentsFailure>> Function({
      required DocumentKind kind,
      required ShipmentId shipment,
    })
    obtain,
    Emitter<DocumentState> emit,
  ) async {
    emit(const DocumentLoading());

    final obtained = await obtain(kind: _kind, shipment: _shipment);
    emit(
      switch (obtained) {
        Success(:final value) => DocumentReady(value),
        Failed(:final failure) => DocumentFailed(failure),
      },
    );
  }
}
