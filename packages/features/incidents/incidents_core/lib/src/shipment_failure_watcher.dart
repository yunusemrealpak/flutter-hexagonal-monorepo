import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:shipments_api/shipments_api.dart';

import 'reason_classifier.dart';
import 'report_incident.dart';

/// Opens an incident whenever a shipment reports that it failed.
///
/// **Scenario 2, in a light feature.** `shipments_application` publishes
/// `ShipmentFailed` and has never heard of incidents; this watcher subscribes
/// and has never heard of `shipments_application`. The only thing the two
/// share is a `DomainEvent` subtype in an `_api` package they both read, and
/// the `DomainEventBus` port in `core_ports`.
///
/// The trade the bus makes is worth restating here, because this is the third
/// time the workspace has taken it: events buy decoupling and cost
/// traceability. Nothing in `shipments` says that a failed delivery opens an
/// incident, and finding that out means searching for subscribers. That is the
/// right trade when the publisher genuinely should not care — and shipments
/// should not: an operation that decided to stop recording incidents would
/// change this file and nothing in the feature that produces the event.
///
/// The incident it opens has no reporter. Attributing it to whoever happened
/// to be signed in would put a courier's name on a record they never made.
final class ShipmentFailureWatcher {
  /// Creates the watcher.
  const ShipmentFailureWatcher({
    required this._events,
    required this._report,
    required this._classify,
    required this._logger,
  });

  final DomainEventBus _events;
  final ReportIncident _report;
  final ReasonClassifier _classify;
  final Logger _logger;

  /// Starts listening.
  ///
  /// Returns the subscription rather than keeping it, so that whoever started
  /// the watcher is the one that can stop it. A watcher that owned its own
  /// subscription would need a `dispose` that a composition root had to
  /// remember, and forgetting it would leave a second watcher opening every
  /// incident twice after a sign-out and back in.
  StreamSubscription<ShipmentFailed> start() =>
      _events.on<ShipmentFailed>().listen(
        (event) => unawaited(_open(event)),
      );

  /// Opens the incident for one event.
  ///
  /// There is nobody to return a failure to — an event arrives from another
  /// part of the product, not from a person — so a failure is logged and the
  /// subscription stays alive. One that died on the first locked write would
  /// silently stop recording for the rest of the shift.
  Future<void> _open(ShipmentFailed event) async {
    final opened = await _report(
      ReportIncidentCommand(
        category: _classify(event.reason),
        shipmentId: event.shipmentId,
        note: event.reason,
      ),
    );

    if (opened case Failed(:final failure)) {
      _logger.log(
        LogLevel.warning,
        'no incident was opened for ${event.shipmentId.value}: $failure',
      );
    }
  }
}
