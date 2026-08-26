/// The messaging UI: the thread a courier reads and writes in, queued messages
/// and all.
///
/// **A queued message stays where it was written.** The list carries sent and
/// unsent messages together, in the order they were typed, because the store
/// *is* the queue. A screen that moved unsent messages to a separate tray
/// would be showing a courier something the domain does not model, and they
/// would have to look in two places to reconstruct what they said.
///
/// **The controller does not reload after sending.** The facade announces the
/// thread and the subscription does the reading; doing both would read the
/// thread twice for every message somebody types.
///
/// **The change stream is filtered here.** The facade announces every thread
/// that moves, because one connection coming back drains several — filtering
/// in the controller is what lets two thread screens exist at once without
/// either redrawing for the other's traffic.
library;

export 'src/messaging_routes.dart';
export 'src/thread_controller.dart';
export 'src/thread_screen.dart';
export 'src/thread_state.dart';
