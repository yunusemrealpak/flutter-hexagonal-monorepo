import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:shipments_api/shipments_api.dart';

import 'shipment_move.dart';

/// The one place a shipment's state changes and is written down.
///
/// Read, apply, persist, cache, publish — in that order, and short-circuiting
/// at the first failure. Every transition in the product goes through here, so
/// there is one answer to what happens around a state change rather than six
/// copies of it that drift.
///
/// What this use case does *not* contain is the rule about which state may
/// follow which. That lives in `Shipment`, and this use case only calls it.
/// The distinction is the whole architecture in miniature: a use case
/// orchestrates, an entity decides.
///
/// Every collaborator arrives through the constructor. There is no locator to
/// reach for inside a package (invariant 1.2.7), so this signature is the
/// complete list of what this class can touch.
final class AdvanceShipment
    implements UseCase<ShipmentMove, Result<Shipment, ShipmentFailure>> {
  /// Creates the use case.
  const AdvanceShipment({
    required this._gateway,
    required this._cache,
    required this._clock,
    required this._events,
    required this._logger,
  });

  final ShipmentGateway _gateway;
  final ShipmentCache _cache;
  final Clock _clock;
  final DomainEventBus _events;
  final Logger _logger;

  @override
  Future<Result<Shipment, ShipmentFailure>> call(ShipmentMove move) async {
    // Read once, and read it here rather than taking a Shipment as input. A
    // caller that passed the entity in would be passing a copy it read at some
    // earlier moment, and two screens acting on the same shipment would each
    // apply their move to a stale one.
    final found = await _gateway.byId(move.id);

    final now = _clock.now();
    final moved = found.flatMap((shipment) => move.applyTo(shipment, now));

    return switch (moved) {
      Failed(:final failure) => Failed(failure),
      Success(value: final shipment) => _persist(shipment, move, now),
    };
  }

  Future<Result<Shipment, ShipmentFailure>> _persist(
    Shipment shipment,
    ShipmentMove move,
    DateTime now,
  ) async {
    final saved = await _gateway.save(shipment);
    if (saved case Failed(:final failure)) return Failed(failure);

    // The cache is written after the gateway and its failure is swallowed on
    // purpose. A shipment the operation has accepted is not un-accepted
    // because this device could not write it to disk; the next read falls
    // through to the gateway and gets the right answer. Failing here instead
    // would turn a full disk into a delivery that did not happen.
    final cached = await _cache.put(shipment);
    if (cached case Failed(:final failure)) {
      _logger.warning(
        'shipment saved remotely but not cached',
        context: {'shipment': shipment.id.value, 'failure': '$failure'},
      );
    }

    final event = move.eventFor(shipment, now);
    if (event != null) _events.publish(event);

    return Success(shipment);
  }
}
