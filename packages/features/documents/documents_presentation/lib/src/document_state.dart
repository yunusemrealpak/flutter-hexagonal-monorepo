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
