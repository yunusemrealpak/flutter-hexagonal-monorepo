/// The notifications UI: the inbox a courier opens, and the badge that tells
/// them to.
///
/// **The badge is exported, the count is not.** `UnreadBadge` is drawn on
/// screens that have nothing else to do with notifications — a route list, a
/// shipment detail — and exporting the widget rather than the number is what
/// keeps those screens from having to hold a `NotificationsFacade` of their
/// own.
///
/// **The count and the list are separate.** They answer different questions
/// and change at different times: the badge follows the count continuously,
/// and the list is read when somebody opens the inbox. Folding one into the
/// other would make every arriving alert redraw a list nobody is looking at.
///
/// **Nothing here renders a sentence.** An `InboxEntry` carries a localisation
/// key and its arguments, `NotificationsStrings` declares the keys this
/// package asks for, and `InboxScreen.describe` maps a sealed failure onto one
/// of them. All three are resolved through the `StringCatalogue` an app
/// installs, so the mapping is checked by the compiler here and the wording is
/// chosen there.
library;

export 'src/inbox_controller.dart';
export 'src/inbox_screen.dart';
export 'src/inbox_state.dart';
export 'src/notifications_routes.dart';
export 'src/notifications_strings.dart';
export 'src/unread_badge.dart';
