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
/// **It ignores the value it is given.** The guard reads
/// `SessionReader.current` when it runs, so all this has to report is *that*
/// something changed. Passing the session through would give the router a
/// second copy of a fact identity already owns, and the two would eventually
/// disagree.
///
/// Fifteen lines in three apps rather than a package they share, for the same
/// reason `PeykRouter` is not shared: three apps making the same small
/// decision are not one decision they have to negotiate.
final class SessionRefresh extends ChangeNotifier {
  /// Subscribes to [changes] and notifies on every event.
  SessionRefresh(Stream<Object?> changes)
    : _subscription = changes.listen(null) {
    _subscription.onData((_) => notifyListeners());
  }

  final StreamSubscription<Object?> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
