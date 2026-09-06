/// What can be asked of the document screen.
///
/// Three cases: obtain the paperwork, produce it again, hand it to the app's
/// share sheet. The first two exist separately because they are different
/// requests — one accepts the archived copy and the other refuses it — and the
/// third emits nothing at all, which is a legitimate shape for an event: it
/// asks for something to happen, not for the screen to change.
sealed class DocumentEvent {
  const DocumentEvent();
}

/// Obtain the document, from the archive if it is there.
final class DocumentRequested extends DocumentEvent {
  /// Creates the event.
  const DocumentRequested();
}

/// Produce the document again, whatever is held.
final class DocumentRefreshRequested extends DocumentEvent {
  /// Creates the event.
  const DocumentRefreshRequested();
}

/// Hand the document on screen to the app's share sheet.
final class DocumentShared extends DocumentEvent {
  /// Creates the event.
  const DocumentShared();
}
