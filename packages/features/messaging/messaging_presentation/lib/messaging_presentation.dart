/// The messaging UI: the thread a courier reads and writes in, queued messages
/// and all.
///
/// **A queued message stays where it was written.** The list carries sent and
/// unsent messages together, in the order they were typed, because the store
/// *is* the queue. A screen that moved unsent messages to a separate tray
/// would be showing a courier something the domain does not model, and they
/// would have to look in two places to reconstruct what they said.
///
/// **The bloc does not read after sending.** The facade announces the thread
/// and the subscription does the reading; doing both would read the thread
/// twice for every message somebody types. The subscription re-dispatches the
/// read event rather than reading itself, so every read goes through one
/// handler with one `restartable()` policy.
///
/// **The change stream is filtered here.** The facade announces every thread
/// that moves, because one connection coming back drains several — filtering
/// in the bloc is what lets two thread screens exist at once without either
/// redrawing for the other's traffic.
///
/// **Sending is `sequential()`, never `droppable()`.** Two messages typed
/// quickly are two different things somebody said, and they have to arrive in
/// the order they were written.
library;

export 'src/messaging_routes.dart';
export 'src/messaging_strings.dart';
export 'src/thread/thread_bloc.dart';
export 'src/thread/thread_event.dart';
export 'src/thread/thread_screen.dart';
export 'src/thread/thread_state.dart';
