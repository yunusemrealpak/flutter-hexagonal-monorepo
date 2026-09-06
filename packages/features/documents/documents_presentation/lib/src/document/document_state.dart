import 'package:documents_api/documents_api.dart';

/// What the document screen can be showing.
sealed class DocumentState {
  const DocumentState();
}

/// Nothing has been asked for yet.
final class DocumentIdle extends DocumentState {
  /// Creates the state.
  const DocumentIdle();
}

/// The document is being obtained.
///
/// One state for "reading the archive" and "asking the server", because a
/// person cannot act on the difference and a screen that showed it would be
/// explaining caching to somebody at a door.
final class DocumentLoading extends DocumentState {
  /// Creates the state.
  const DocumentLoading();
}

/// The document is here.
///
/// **No `==`, deliberately.** `Document` is an entity, and an entity's
/// equality in this workspace is its identifier alone — so a state that
/// delegated to it would report the archived copy and a freshly produced one
/// as the same state, and `Bloc` drops an emission that compares equal to the
/// one before it. A courier who pressed *produce again* would watch the old
/// size stay on screen.
final class DocumentReady extends DocumentState {
  /// Creates the state.
  const DocumentReady(this.document);

  /// The paperwork.
  final Document document;
}

/// It could not be produced.
final class DocumentFailed extends DocumentState {
  /// Creates the state.
  const DocumentFailed(this.failure);

  /// What went wrong, in documents' own words.
  final DocumentsFailure failure;
}
