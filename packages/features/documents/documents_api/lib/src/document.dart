import 'package:core_kernel/core_kernel.dart';
import 'package:shipments_api/shipments_api.dart';

import 'document_id.dart';
import 'document_kind.dart';
import 'documents_failure.dart';

/// One rendered piece of paperwork.
///
/// **It carries its bytes.** A document that carried a URL would be a document
/// that stops existing when the signal does, and the reason a courier opens
/// one is usually that somebody at a door is asking to see it.
///
/// The bytes are held as a `List<int>` rather than a `Uint8List`, because
/// `Uint8List` lives in `dart:typed_data` — which is fine here, and would stop
/// being fine the moment this contract had to be read by something that is not
/// a Dart VM. The adapter that produces the bytes converts once; nothing else
/// in the feature cares.
final class Document extends Entity<DocumentId> {
  const Document._({
    required super.id,
    required this.kind,
    required this.shipment,
    required this.mediaType,
    required this.bytes,
    required this.renderedAt,
  });

  /// Records a document that has just been produced.
  ///
  /// [renderedAt] comes from a `Clock` — rule A1, and what the archive's
  /// eviction order is decided by.
  ///
  /// Empty bytes are refused. A zero-length PDF opens as a blank screen, and
  /// the courier holding it has no way to tell that from a document that is
  /// genuinely empty.
  static Result<Document, DocumentsFailure> rendered({
    required DocumentKind kind,
    required ShipmentId shipment,
    required String mediaType,
    required List<int> bytes,
    required DateTime renderedAt,
  }) {
    if (bytes.isEmpty) {
      return const Failed(
        MalformedDocument(field: 'bytes', reason: 'it is empty'),
      );
    }
    if (mediaType.trim().isEmpty) {
      return const Failed(
        MalformedDocument(field: 'mediaType', reason: 'it is empty'),
      );
    }

    return Success(
      Document._(
        id: DocumentId.of(kind: kind, shipment: shipment),
        kind: kind,
        shipment: shipment,
        mediaType: mediaType.trim(),
        bytes: List.unmodifiable(bytes),
        renderedAt: renderedAt.toUtc(),
      ),
    );
  }

  /// Which piece of paperwork.
  final DocumentKind kind;

  /// Which parcel it is about.
  final ShipmentId shipment;

  /// What it is, as a media type — `application/pdf`, `image/png`.
  final String mediaType;

  /// The document itself.
  ///
  /// Unmodifiable, so a document handed to a viewer and a share sheet at once
  /// cannot be changed by either.
  final List<int> bytes;

  /// When it was produced, in UTC.
  final DateTime renderedAt;

  /// How big it is.
  int get sizeInBytes => bytes.length;

  /// Whether this document was produced before [instant].
  ///
  /// What "stale" means is not this type's decision — a waybill does not
  /// change and a receipt does — so the comparison is offered and the policy
  /// is somebody else's.
  bool renderedBefore(DateTime instant) => renderedAt.isBefore(instant.toUtc());
}
