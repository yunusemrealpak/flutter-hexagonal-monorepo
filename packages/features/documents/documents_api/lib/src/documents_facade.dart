import 'package:core_kernel/core_kernel.dart';
import 'package:shipments_api/shipments_api.dart';

import 'document.dart';
import 'document_kind.dart';
import 'documents_failure.dart';

/// What the rest of the product may ask documents to do.
///
/// A driving port, speaking in `ShipmentId`. The driven ports beside it speak
/// in `String` and in whole documents.
///
/// There is no `share` here, and the omission is the design: sharing is a
/// platform capability with no `platform/*` package behind it yet, so the app
/// supplies it as a callback to the screen — the same decision
/// `delivery_presentation` made about the camera in phase 5. A `share` on this
/// port would be a port whose adapter could not live in this feature.
abstract interface class DocumentsFacade {
  /// Produces [kind] for [shipment], or hands back the copy already held.
  ///
  /// Cheap to call twice: the archive answers the second time. That is the
  /// whole reason `DocumentId` is derived rather than minted.
  Future<Result<Document, DocumentsFailure>> obtain({
    required DocumentKind kind,
    required ShipmentId shipment,
  });

  /// Produces [kind] for [shipment] again, whatever is held.
  ///
  /// For the case the cache cannot detect: a template changed, or a document
  /// was produced before the parcel's details were corrected. A courier does
  /// not know that; somebody at a desk does, and this is the button they are
  /// told to press.
  Future<Result<Document, DocumentsFailure>> refresh({
    required DocumentKind kind,
    required ShipmentId shipment,
  });
}
