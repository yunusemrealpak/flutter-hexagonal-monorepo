import 'dart:convert';

import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:documents_api/documents_api.dart';
import 'package:shipments_api/shipments_api.dart';

/// Keeps produced documents on the device, and throws the oldest away.
///
/// **The cap is the point.** A courier's phone is not where a year of PDFs
/// belongs, and an archive without one turns into a support call about
/// storage three months after launch. Everything here can be produced again,
/// which is what makes throwing it away safe — and it is why
/// `DocumentArchive.read` answering `DocumentMissing` is an ordinary outcome
/// rather than a fault.
///
/// **Oldest render first**, not least recently opened. A least-recently-used
/// policy would need a write on every read, which on a phone is a write on
/// every document a courier glances at; the parcel somebody is asking about
/// today was rendered today, so render order is a good enough proxy and costs
/// nothing.
final class CappedDocumentArchive implements DocumentArchive {
  /// Creates the archive over the store, keeping at most [capacity] documents.
  const CappedDocumentArchive({required this._store, this.capacity = 20});

  final KeyValueStore _store;

  /// How many documents are kept before the oldest is dropped.
  final int capacity;

  /// The key this archive writes.
  static const key = 'documents.archive';

  @override
  Future<Result<Document, DocumentsFailure>> read(String id) async {
    final held = await _read();
    if (held case Failed(:final failure)) {
      return Failed(failure);
    }

    final documents = (held as Success<List<Document>, DocumentsFailure>).value;
    for (final document in documents) {
      if (document.id.value == id) {
        return Success(document);
      }
    }
    return Failed(DocumentMissing(id));
  }

  @override
  Future<Result<void, DocumentsFailure>> put(Document document) async {
    final held = await _read();
    if (held case Failed(:final failure)) {
      return Failed(failure);
    }

    final documents = [
      ...(held as Success<List<Document>, DocumentsFailure>).value.where(
        (existing) => existing.id != document.id,
      ),
      document,
    ]..sort((a, b) => a.renderedAt.compareTo(b.renderedAt));

    final kept = documents.length <= capacity
        ? documents
        : documents.sublist(documents.length - capacity);
    return _write(kept);
  }

  Future<Result<List<Document>, DocumentsFailure>> _read() async {
    final raw = await _store.read(key);

    return switch (raw) {
      Failed(:final failure) => Failed(_translate(failure)),
      Success(value: null) => const Success([]),
      Success(value: final text?) => _decode(text),
    };
  }

  /// Reads the archive, treating anything unreadable as an empty archive.
  ///
  /// The one place in phase 6 where a corrupt store is *not* reported. Every
  /// other feature's stored state is the only copy there is; this one is a
  /// cache of things the server will produce again, so the honest recovery is
  /// to drop it and re-render — and telling a courier that their document
  /// cache is corrupt is telling them about a problem they cannot act on.
  Result<List<Document>, DocumentsFailure> _decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const Success([]);
      }

      final documents = <Document>[];
      for (final element in decoded) {
        if (element is! Map<String, Object?>) {
          return const Success([]);
        }
        final document = _document(element);
        if (document == null) {
          return const Success([]);
        }
        documents.add(document);
      }
      return Success(documents);
    } on FormatException {
      return const Success([]);
    }
  }

  Document? _document(Map<String, Object?> json) {
    final kind = json['kind'];
    final shipment = json['shipment'];
    final mediaType = json['mediaType'];
    final bytes = json['bytes'];
    final renderedAt = json['renderedAt'];
    if (kind is! String ||
        shipment is! String ||
        mediaType is! String ||
        bytes is! String ||
        renderedAt is! String) {
      return null;
    }

    final instant = DateTime.tryParse(renderedAt);
    if (instant == null) {
      return null;
    }

    final parsed = DocumentKind.parse(kind);
    if (parsed case Failed()) {
      return null;
    }
    final parcel = ShipmentId.parse(shipment);
    if (parcel case Failed()) {
      return null;
    }

    final document = Document.rendered(
      kind: (parsed as Success<DocumentKind, DocumentsFailure>).value,
      shipment: (parcel as Success<ShipmentId, ShipmentFailure>).value,
      mediaType: mediaType,
      bytes: base64Decode(bytes),
      renderedAt: instant,
    );
    return switch (document) {
      Success(:final value) => value,
      Failed() => null,
    };
  }

  Future<Result<void, DocumentsFailure>> _write(
    List<Document> documents,
  ) async {
    final written = await _store.write(
      key,
      jsonEncode([
        for (final document in documents)
          {
            'kind': document.kind.name,
            'shipment': document.shipment.value,
            'mediaType': document.mediaType,
            'bytes': base64Encode(document.bytes),
            'renderedAt': document.renderedAt.toIso8601String(),
          },
      ]),
    );

    return switch (written) {
      Failed(:final failure) => Failed(_translate(failure)),
      Success() => const Success(null),
    };
  }

  DocumentsFailure _translate(StoreFailure failure) => switch (failure) {
    StoreCorrupted(:final key) => ArchiveUnavailable(
      detail: 'corrupt at $key',
    ),
    StoreUnavailable(:final detail) => ArchiveUnavailable(detail: detail),
    StoreOutOfSpace() => const ArchiveUnavailable(
      detail: 'no room for the archive',
    ),
  };
}
