/// The documents use cases, the renderer that produces paperwork over HTTP,
/// and the archive that keeps a device from filling with it.
///
/// **Rendering happens on the server.** A waybill is a legal document whose
/// layout changes when the operation's terms do; rendering it on a phone would
/// mean every courier carrying a version of the template, and a fleet updating
/// over weeks would produce weeks of documents that disagree.
///
/// **The archive is a cache with a cap.** Everything in it can be produced
/// again, which is what makes eviction safe — and a phone is not where a year
/// of PDFs belongs. Eviction is by render order rather than by last use,
/// because a least-recently-used policy needs a write on every read, and on a
/// phone that is a write every time somebody glances at a document.
///
/// **Neither cache failure reaches a courier.** An archive that cannot be read
/// does not stop a render; an archive that cannot be written does not fail an
/// answer. Both are logged, because a cache failing silently every time is a
/// bug somebody should see — but a full disk must not become a document nobody
/// can show at a door.
///
/// The halves:
///
/// - `ObtainDocument` and `DocumentsCoordinator` are the application half.
/// - `HttpDocumentRenderer` and `CappedDocumentArchive` are the infrastructure
///   half. They import no use case, and no use case imports them.
library;

export 'src/capped_document_archive.dart';
export 'src/documents_coordinator.dart';
export 'src/http_document_renderer.dart';
export 'src/obtain_document.dart';
