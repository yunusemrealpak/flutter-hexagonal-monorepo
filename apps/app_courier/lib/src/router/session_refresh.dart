import 'dart:async';

import 'package:flutter/foundation.dart';

/// Notifies whenever the session changes, so that the router's guard runs.
///
/// `GoRouter.refreshListenable` takes a `Listenable`. `SessionReader.changes`
/// offers a `Stream<Session?>`, because a stream is what a port with several
/// possible listeners can honestly promise. This is the adapter between the
/// two, and go_router no longer ships one — `GoRouterRefreshStream` was part
/// of the package until version 17.
///
/// **It never passes the value on.** The guard reads `SessionReader.current`
/// when it runs, so all this has to report is *that* something changed.
/// Handing the session to the router would give it a second copy of a fact
/// identity already owns, and the two would eventually disagree.
///
/// It does read one thing off the event, and only one: whether there is
/// anybody. `null` means the session ended, and an ended session is the one
/// case where the previous person's intent must not survive — see the
/// constructor. That is a `null` check against what the port already
/// promises, not knowledge of what a `Session` is; this file still does not
/// import `identity_api`.
///
/// Fifteen lines in three apps rather than a package they share, for the same
/// reason `PeykRouter` is not shared: three apps making the same small
/// decision are not one decision they have to negotiate.
final class SessionRefresh extends ChangeNotifier {
  /// Subscribes to [changes] and notifies on every event.
  ///
  /// [onSessionEnded] runs the moment a session ends, before the guard does.
  /// It exists because of what the guard does with the location it refuses: a
  /// person sent to sign-in carries `?from=` so that the parcel they followed
  /// a link to survives signing in — and an *ended* session is refused at
  /// whatever screen its owner was on. Without this, the next person to sign
  /// in on the handset lands on the previous courier's parcel.
  ///
  /// Interception and ejection look identical to `redirectFor`: both are a
  /// session-requiring route with no session. They are told apart here, the
  /// only place that sees the transition, and the app answers by clearing the
  /// location before the guard reads it.
  SessionRefresh(Stream<Object?> changes, {VoidCallback? onSessionEnded})
    : _subscription = changes.listen(null) {
    _subscription.onData((session) {
      if (session == null) {
        onSessionEnded?.call();
      }
      notifyListeners();
    });
  }

  final StreamSubscription<Object?> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
