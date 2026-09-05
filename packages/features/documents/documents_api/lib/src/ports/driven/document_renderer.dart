import 'package:core_kernel/core_kernel.dart';

import '../../entities/document.dart';
import '../../failures/documents_failure.dart';
import '../../values/document_kind.dart';

/// Produces a document.
///
/// A driven port in the product's words. It takes the raw shipment identifier
/// rather than a `ShipmentId`, for the reason §2.1 gives — an adapter should
/// not have to see `shipments` to ask for a PDF — and answers with a whole
/// `Document`, which does name one. That asymmetry is deliberate and is the
/// one place this feature bends toward convenience: the identifier the adapter
/// is *given* is the identifier it hands back, so it rebuilds nothing.
abstract interface class DocumentRenderer {
  /// Produces [kind] for the parcel identified by [shipmentId].
  ///
  /// `RenderFailed` is worth retrying; `DocumentRefused` never is.
  Future<Result<Document, DocumentsFailure>> render({
    required DocumentKind kind,
    required String shipmentId,
  });
}
