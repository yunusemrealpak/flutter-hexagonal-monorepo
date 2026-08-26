import 'package:core_kernel/core_kernel.dart';
import 'package:documents_api/documents_api.dart';
import 'package:shipments_api/shipments_api.dart';

import 'obtain_document.dart';

/// The one implementation of `DocumentsFacade`.
///
/// Two methods over one use case, and the flag between them is the only
/// difference. That is deliberate: `obtain` and `refresh` are two intentions a
/// person has — "show me the waybill" and "that one is out of date" — and
/// making them two methods is what lets a screen offer the second without
/// explaining caching to anybody.
final class DocumentsCoordinator implements DocumentsFacade {
  /// Creates the coordinator over its use case.
  const DocumentsCoordinator({required this._obtain});

  final ObtainDocument _obtain;

  @override
  Future<Result<Document, DocumentsFailure>> obtain({
    required DocumentKind kind,
    required ShipmentId shipment,
  }) => _obtain(ObtainDocumentCommand(kind: kind, shipment: shipment));

  @override
  Future<Result<Document, DocumentsFailure>> refresh({
    required DocumentKind kind,
    required ShipmentId shipment,
  }) => _obtain(
    ObtainDocumentCommand(kind: kind, shipment: shipment, fresh: true),
  );
}
