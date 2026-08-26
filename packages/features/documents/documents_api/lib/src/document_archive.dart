import 'package:core_kernel/core_kernel.dart';

import 'document.dart';
import 'documents_failure.dart';

/// Where produced documents are kept so they need not be produced again.
///
/// **It is a cache with a promise, not a filing cabinet.** Anything in it can
/// be produced again from the renderer, which is what lets it evict — and it
/// has to evict, because a courier's phone is not where a year of PDFs
/// belongs. `read` answering [DocumentMissing] is the ordinary outcome for
/// anything old, and the correct response is to render it again.
///
/// The eviction policy is the adapter's, not the port's. A device archive
/// evicts on size; a dispatcher's workstation might not evict at all.
abstract interface class DocumentArchive {
  /// The document stored under [id], or [DocumentMissing].
  Future<Result<Document, DocumentsFailure>> read(String id);

  /// Stores [document], replacing any with the same identifier.
  ///
  /// Replacement rather than refusal, because the identifier is derived: the
  /// second render of a waybill is the same document produced from a possibly
  /// newer template, and the newer one is the one to keep.
  Future<Result<void, DocumentsFailure>> put(Document document);
}
