/// The notifications UI: the inbox a courier opens, and the badge that tells
/// them to.
///
/// **The badge is exported, the count is not.** `UnreadBadge` is drawn on
/// screens that have nothing else to do with notifications — a route list, a
/// shipment detail — and exporting the widget rather than the number is what
/// keeps those screens from having to hold a `NotificationsFacade` of their
/// own.
///
/// **The count and the list are separate blocs, in separate folders.** They
/// answer different questions and change at different rates: the badge follows
/// the count continuously and the list is read when somebody opens the inbox.
/// One bloc carrying both would emit a state with a list in it every time an
/// alert arrived, and every app that wanted a badge on a tab would have to
/// build an inbox to get one.
///
/// `UnreadBloc` is also where the workspace's one subscription-holding bloc
/// lives. It follows the count with `emit.onEach` inside a `restartable()`
/// handler, which is what replaces a nullable subscription field, a guard
/// against watching twice, and a `dispose` override.
///
/// **Nothing here renders a sentence.** An `InboxEntry` carries a localisation
/// key and its arguments, `NotificationsStrings` declares the keys this
/// package asks for, and `InboxScreen.describe` maps a sealed failure onto one
/// of them. All three are resolved through the `StringCatalogue` an app
/// installs, so the mapping is checked by the compiler here and the wording is
/// chosen there.
library;

export 'src/inbox/inbox_bloc.dart';
export 'src/inbox/inbox_event.dart';
export 'src/inbox/inbox_screen.dart';
export 'src/inbox/inbox_state.dart';
export 'src/notifications_routes.dart';
export 'src/notifications_strings.dart';
export 'src/unread/unread_badge.dart';
export 'src/unread/unread_bloc.dart';
export 'src/unread/unread_event.dart';
export 'src/unread/unread_state.dart';
