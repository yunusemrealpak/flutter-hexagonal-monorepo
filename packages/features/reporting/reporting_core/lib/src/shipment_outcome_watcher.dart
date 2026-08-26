import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:reporting_api/reporting_api.dart';
import 'package:shipments_api/shipments_api.dart';

import 'record_outcome.dart';

/// Builds the totals from what other features publish.
///
/// **A read model, and the arrow points the way scenario 3 describes.**
/// `shipments_application` publishes `ShipmentDelivered`, `ShipmentFailed` and
/// `ShipmentReturned` and has never heard of reporting. This package
/// subscribes and has never heard of `shipments_application`. Both know only
/// the `DomainEventBus` port and three `DomainEvent` subtypes in an `_api`
/// they already read.
///
/// It is a different use of the bus from `incidents`, and the difference is
/// worth naming. Incidents *reacts* — one event, one new thing in the world.
/// Reporting *accumulates* — every event moves a number, and the numbers are
/// the only thing this feature owns. That is why its facade is read-only:
/// there is no way to tell reporting something happened except by it happening.
///
/// Three subscriptions rather than one over `DomainEvent`, because
/// `DomainEventBus.on<T>()` is typed and a single subscription would have to
/// re-discover the type with a `switch` the compiler could not check.
final class ShipmentOutcomeWatcher {
  /// Creates the watcher.
  const ShipmentOutcomeWatcher({
    required this._events,
    required this._record,
    required this._logger,
  });

  final DomainEventBus _events;
  final RecordOutcome _record;
  final Logger _logger;

  /// Starts listening, and hands back the subscriptions.
  ///
  /// The caller owns them, for the reason `ShipmentFailureWatcher` gives: a
  /// watcher that kept its own would need a `dispose` a composition root had
  /// to remember, and forgetting it would double-count every parcel after a
  /// sign-out and back in.
  List<StreamSubscription<DomainEvent>> start() => [
    _events.on<ShipmentDelivered>().listen(
      (event) => unawaited(
        _count(event.shipmentId, ShipmentOutcome.delivered, event.occurredAt),
      ),
    ),
    _events.on<ShipmentFailed>().listen(
      (event) => unawaited(
        _count(event.shipmentId, ShipmentOutcome.failed, event.occurredAt),
      ),
    ),
    _events.on<ShipmentReturned>().listen(
      (event) => unawaited(
        _count(event.shipmentId, ShipmentOutcome.returned, event.occurredAt),
      ),
    ),
  ];

  /// Records one outcome.
  ///
  /// A failure is logged and the subscription stays alive. There is nobody to
  /// return it to, and a read model that stopped counting on the first locked
  /// write would show a dispatcher a plausible number that had quietly
  /// stopped moving — which is worse than one that is obviously broken.
  Future<void> _count(
    ShipmentId shipment,
    ShipmentOutcome outcome,
    DateTime occurredAt,
  ) async {
    final recorded = await _record(
      RecordOutcomeCommand(
        shipment: shipment,
        outcome: outcome,
        occurredAt: occurredAt,
      ),
    );

    if (recorded case Failed(:final failure)) {
      _logger.log(
        LogLevel.warning,
        'the totals were not updated for ${shipment.value}: $failure',
      );
    }
  }
}
