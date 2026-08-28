import 'dart:async';

import 'package:incidents_core/incidents_core.dart';
import 'package:injectable/injectable.dart';
import 'package:payments_application/payments_application.dart';

/// Everything in this app that listens to the event bus.
///
/// Two watchers, not three: `reporting` is a dispatcher's feature and this app
/// does not mount it. Which is the shape scenario 2 has when it is real — a
/// publisher with no subscriber in one app and two in another, and no package
/// on either side that knows the difference.
///
/// `ShipmentFailureWatcher.start()` returns its subscription rather than
/// keeping it, deliberately, so that whoever started it can stop it. This
/// class is that whoever.
@singleton
final class CourierWatchers {
  /// Starts every watcher this app composes.
  CourierWatchers({
    required this.reconciler,
    required ShipmentFailureWatcher incidents,
  }) : _incidents = incidents.start() {
    reconciler.start();
  }

  /// The watcher that keeps its own subscription, idempotently.
  final CollectionReconciler reconciler;

  final StreamSubscription<Object?> _incidents;

  /// Stops them.
  ///
  /// Called when a courier signs out. A subscription that outlived a session
  /// would keep opening incidents against an actor who is no longer there.
  Future<void> dispose() async {
    await _incidents.cancel();
    await reconciler.dispose();
  }
}
