import 'package:push_messaging/push_messaging.dart';

import '../router/courier_flow.dart';

/// Where a pressed notification opens this app.
///
/// The entry half of what [CourierFlow] does for continuation, and deliberately
/// the same shape: a pure function from something that happened to a
/// `(route, parameters)` record. A record rather than a call to the router is
/// what makes the mapping a value a test can read, and the test asserts that
/// every route it can name is a route this app actually mounted.
///
/// **It lives in the app for the reason every route table does.** Route names
/// are declared in presentation packages, and `push_messaging` may not see one
/// — it is a `platform/*` package, whose whole row in §1.1 is `core_kernel`,
/// `core_ports` and Flutter. A `PushMessageKind` cannot know that a courier's
/// app has a manifest, and a manifest cannot know a push exists. This class is
/// the one place that knows both, which is the composition root's job.
///
/// **Null is an answer, not a gap.** A push of a kind this version does not
/// recognise, and a push that names no thread, both open nothing: the app
/// starts where it normally starts. `PushMessageKind.unknown` is normal
/// traffic — a fleet updates over weeks — so treating it as an error here
/// would make a newer server a crash on an older handset.
final class CourierEntryPoints {
  /// Creates the mapping.
  const CourierEntryPoints();

  /// Where [message] opens the app, or null when it opens nothing.
  ///
  /// The `switch` is exhaustive over `PushMessageKind`, so a kind added to the
  /// platform package stops this file compiling rather than silently opening
  /// nothing — the same guarantee `CourierFlow.afterProof` gets from a sealed
  /// `AttemptOutcome`.
  FlowStep? forMessage(PushMessage message) => switch (message.kind) {
    // The manifest, not a detail screen: a courier's app has no screen for one
    // shipment on its own, and the assignment's whole point is that a new stop
    // has appeared in the list. `shipmentId` is deliberately unused here —
    // opening the list is the honest answer, and inventing a destination for
    // an identifier would be a screen nobody wrote.
    PushMessageKind.shipmentAssigned => (
      route: 'shipments.courier.manifest',
      parameters: const {},
    ),
    PushMessageKind.dispatchMessage => _thread(message),
    PushMessageKind.routeUpdated => (
      route: 'routing.myRoute',
      parameters: const {},
    ),
    PushMessageKind.unknown => null,
  };

  /// The thread a dispatch message names, when it names one.
  ///
  /// A push about a thread that does not say which thread cannot open one.
  /// That is a server-side mistake and it arrives as ordinary traffic, so the
  /// answer is to open nothing rather than to guess or to throw.
  FlowStep? _thread(PushMessage message) {
    final thread = message.threadId;
    if (thread == null || thread.isEmpty) {
      return null;
    }
    return (route: 'messaging.thread', parameters: {'threadId': thread});
  }

  /// Every destination this mapping can name.
  ///
  /// The input to the test that checks each one against the routes the app
  /// mounted, exactly as `CourierFlow.destinations` is. A route name is a
  /// string, and this is what stops a mistyped one from being discovered by a
  /// courier who pressed a notification and landed on nothing.
  static const Set<String> destinations = {
    'shipments.courier.manifest',
    'messaging.thread',
    'routing.myRoute',
  };
}
