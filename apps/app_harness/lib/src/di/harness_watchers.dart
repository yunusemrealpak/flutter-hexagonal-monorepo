import 'dart:async';

import 'package:incidents_core/incidents_core.dart';
import 'package:injectable/injectable.dart';
import 'package:payments_application/payments_application.dart';
import 'package:reporting_core/reporting_core.dart';

/// Everything in this app that listens to the event bus, and the one thing
/// that can stop it.
///
/// It exists because two of the three watchers *return* their subscription
/// from `start()` rather than keeping it, and their doc comments say why:
/// "whoever started the watcher is the one that can stop it". Calling
/// `start()` and discarding the result would throw away exactly what those
/// packages hand the composition root, and the failure mode is the one they
/// name — sign out, sign back in, and every incident is opened twice.
///
/// So this class is the answer to a question the packages asked. It is
/// app-layer code with no product logic in it at all: three subscriptions and
/// a way to cancel them.
///
/// `CollectionReconciler` is the exception and keeps its own subscription,
/// idempotently. It is listed here anyway, because a reader looking for
/// "what is listening in this app" should find one list rather than two.
@singleton
final class HarnessWatchers {
  /// Starts every watcher this app composes.
  HarnessWatchers({
    required this.reconciler,
    required ShipmentFailureWatcher incidents,
    required ShipmentOutcomeWatcher reporting,
  }) : _incidents = incidents.start(),
       _reporting = reporting.start() {
    reconciler.start();
  }

  /// The one watcher that keeps its own subscription.
  ///
  /// Public because it is the only one a caller could usefully hold: the
  /// other two handed their subscriptions to this class and have nothing left
  /// to offer.
  final CollectionReconciler reconciler;

  final StreamSubscription<Object?> _incidents;
  final List<StreamSubscription<Object?>> _reporting;

  /// Stops all of them.
  ///
  /// Nothing in this app calls it — a harness runs for the length of a test
  /// and then the isolate ends. It exists because a subscription that cannot
  /// be cancelled is a subscription that will be started twice by somebody
  /// eventually, and because the test below asserts that stopping works.
  Future<void> dispose() async {
    await _incidents.cancel();
    await Future.wait(_reporting.map((it) => it.cancel()));
    await reconciler.dispose();
  }
}
