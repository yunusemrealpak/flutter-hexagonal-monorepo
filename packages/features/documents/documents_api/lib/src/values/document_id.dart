import 'package:core_kernel/core_kernel.dart';
import 'package:shipments_api/shipments_api.dart';

import '../failures/documents_failure.dart';
import 'document_kind.dart';

/// Identifies one document.
///
/// **Derived from the parcel and the kind**, and that is the whole caching
/// story of this feature: `waybill:SHP-42` is the same document however many
/// times somebody asks for it, so the archive can answer the second request
/// without spending a courier's data allowance on a second render.
///
/// A minted identifier would make every request a new document and every open
/// a download. The trade is that a template change does not produce a new
/// identifier — which is why the archive evicts rather than keeping documents
/// for ever, and why a re-render is always available.
final class DocumentId extends ValueObject<String> {
  const DocumentId._(super.value);

  /// The identifier of [kind] for [shipment].
  factory DocumentId.of({
    required DocumentKind kind,
    required ShipmentId shipment,
  }) => DocumentId._('${kind.name}:${shipment.value}');

  /// Reads a document identifier from [raw].
  static Result<DocumentId, DocumentsFailure> parse(String raw) {
    final parts = raw.trim().split(':');
    if (parts.length != 2 || parts.any((part) => part.isEmpty)) {
      return Failed(
        MalformedDocument(
          field: 'id',
          reason: '"$raw" is not a kind and a shipment',
        ),
      );
    }
    return DocumentKind.parse(parts.first).map((_) => DocumentId._(raw.trim()));
  }
}
