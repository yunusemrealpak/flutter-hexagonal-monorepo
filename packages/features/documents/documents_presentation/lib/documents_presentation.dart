/// The documents UI: the screen that shows a piece of paperwork and hands it
/// to whatever the app shares with.
///
/// **Sharing arrives as a callback.** A presentation package may not depend on
/// `platform/*`, and sharing has no `platform/*` package behind it — so the
/// app supplies a function and this package calls it. The same decision
/// `delivery_presentation` made about the camera in phase 5.
///
/// An app that supplies none gets a screen with no share control, rather than
/// one that does nothing when pressed.
///
/// **The screen does not render the document.** A PDF viewer is a platform
/// capability too. What is shown is the document's identity and size; an app
/// with a viewer puts it where the placeholder is.
///
/// **Loading is one state.** "Reading the archive" and "asking the server" are
/// a distinction a person cannot act on, and a screen that showed it would be
/// explaining caching to somebody standing at a door.
library;

export 'src/document_controller.dart';
export 'src/document_screen.dart';
export 'src/document_state.dart';
export 'src/documents_routes.dart';
export 'src/documents_strings.dart';
