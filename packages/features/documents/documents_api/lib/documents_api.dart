/// The documents contract: the paperwork a round produces, where it is kept,
/// and what it costs to produce it twice.
///
/// **`DocumentId` is derived, and that is the caching story.**
/// `waybill:SHP-42` is the same document however many times somebody asks for
/// it, so the archive answers the second request without spending a courier's
/// data allowance on a second render. The cost of that choice is that a
/// template change produces no new identifier — which is why the archive
/// evicts, and why `DocumentsFacade.refresh` exists for the person who knows
/// something the cache cannot.
///
/// **A document carries its bytes.** One that carried a URL would stop
/// existing when the signal did, and the reason a courier opens one is usually
/// that somebody at a door is asking to see it.
///
/// **There is no `share`.** Sharing is a platform capability with no
/// `platform/*` package behind it yet, so an app supplies it as a callback to
/// the screen — the same decision `delivery_presentation` made about the
/// camera. A `share` on the facade would be a port whose adapter could not
/// live in this feature.
library;

export 'src/document.dart';
export 'src/document_archive.dart';
export 'src/document_id.dart';
export 'src/document_kind.dart';
export 'src/document_renderer.dart';
export 'src/documents_facade.dart';
export 'src/documents_failure.dart';
