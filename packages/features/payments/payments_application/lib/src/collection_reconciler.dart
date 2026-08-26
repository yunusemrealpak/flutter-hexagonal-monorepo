import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:delivery_api/delivery_api.dart';
import 'package:payments_api/payments_api.dart';

import 'settlement_updates.dart';

/// Closes a collection when the delivery it belongs to completes.
///
/// **This is scenario 2 from the subscriber's side, and the whole of payments'
/// knowledge of delivery is the two lines that name `DeliveryCompleted`.**
/// `delivery_application` publishes it on the `DomainEventBus` port in
/// `core_ports` and never learns that anybody listens; this class listens and
/// never learns who published. Neither `_application` package appears in the
/// other's pubspec. What they share is one type in `delivery_api` and a bus.
///
/// The trade the bus makes is worth naming, because this file is where it is
/// paid for: events buy decoupling and cost traceability. Nothing in
/// `delivery_application` says that a completed delivery closes a cash
/// collection, and finding that out means searching for subscribers — this
/// one. That is the right trade here, because delivery genuinely should not
/// care: a parcel is handed over whether or not money was owed on it.
///
/// **What it does is narrow on purpose.** It closes an outstanding *cash*
/// collection and nothing else. A card that was never authorised does not
/// become authorised because a parcel arrived, and inventing that would be
/// inventing money. A collection that has already settled is left alone, which
/// is also what makes the subscriber safe to run twice — an event bus that
/// redelivers, a queue that drains a delivery late, an app that resubscribes
/// on resume.
///
/// It is a class with a lifecycle rather than a use case, because it is
/// *started* rather than called: the composition root subscribes it when the
/// container comes up and disposes it when the container goes down.
final class CollectionReconciler {
  /// Creates the reconciler over its ports.
  CollectionReconciler({
    required this._events,
    required this._gateway,
    required this._settlements,
    required this._logger,
  });

  final DomainEventBus _events;
  final PaymentsGateway _gateway;
  final SettlementStore _settlements;
  final Logger _logger;

  StreamSubscription<DeliveryCompleted>? _subscription;

  /// Starts listening for completed deliveries.
  ///
  /// Idempotent: a container that started twice keeps one subscription, so a
  /// hot restart does not double every reconciliation.
  void start() {
    _subscription ??= _events.on<DeliveryCompleted>().listen(
      (event) => unawaited(reconcile(event)),
    );
  }

  /// Closes the collection [event] belongs to, if there is one to close.
  ///
  /// Public and awaitable so that a test can assert on the outcome without
  /// racing a stream. The subscription calls the same method.
  Future<void> reconcile(DeliveryCompleted event) async {
    final shipmentId = event.shipment.value;

    final PaymentAttempt? attempt;
    switch (await _gateway.attemptFor(shipmentId)) {
      case Failed(:final failure):
        // Nothing is retried here. The event has already been consumed, and a
        // reconciler that swallowed a failure quietly would leave a collection
        // open with nobody knowing. The daily settlement is where a human
        // notices.
        _logger.warning(
          'could not read the collection for a completed delivery',
          context: {'shipment': shipmentId, 'failure': '$failure'},
        );
        return;
      case Success(:final value):
        attempt = value;
    }

    // Most parcels are prepaid. No collection is the ordinary case, not a
    // problem.
    if (attempt == null) return;

    // Already settled — the courier took the money at the door and the
    // collection closed itself. Running twice has to be free.
    if (!attempt.isOutstanding) return;

    if (!attempt.request.method.isCash) {
      // A card that was never authorised does not become authorised because a
      // parcel arrived.
      _logger.info(
        'a delivery completed with an unauthorised card collection open',
        context: {'shipment': shipmentId},
      );
      return;
    }

    // Domain time, from the event: when the hand-over happened, not when this
    // subscriber heard about it. The two are hours apart when a delivery is
    // drained from an outbox.
    final PaymentAttempt taken;
    switch (attempt.taken(at: event.occurredAt)) {
      case Failed(:final failure):
        _logger.warning(
          'a collection could not be closed against its delivery',
          context: {'shipment': shipmentId, 'failure': '$failure'},
        );
        return;
      case Success(:final value):
        taken = value;
    }

    // The gateway is idempotent by key, so a reconciliation that runs twice
    // records once — which is the property that lets this method be safe
    // without a lock, a flag or a table of processed events.
    final recorded = await _gateway.collect(taken);
    if (recorded case Failed(:final failure)) {
      _logger.warning(
        'a collection could not be recorded against its delivery',
        context: {'shipment': shipmentId, 'failure': '$failure'},
      );
      return;
    }

    final updated = await SettlementUpdates.include(
      taken,
      store: _settlements,
      at: event.occurredAt,
    );
    if (updated case Failed(:final failure)) {
      _logger.warning(
        "a collection closed; the day's total was not updated",
        context: {'failure': '$failure'},
      );
    }
  }

  /// Stops listening.
  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
