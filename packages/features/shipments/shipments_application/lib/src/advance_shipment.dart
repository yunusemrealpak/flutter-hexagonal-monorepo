import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:payments_api/payments_api.dart';
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
/// **The payment guard is scenario 1's second half.** Before a hand-over is
/// recorded, this use case asks `payments_api`'s `PaymentStatusReader` whether
/// money is still owed. It reaches a *contract* — `payments_application` is
/// not in this package's pubspec and never will be — while `payments_api`
/// names `shipments_api` in return. Two features that need each other, and no
/// cycle, because a contract package depends on no implementation.
///
/// The guard is asked of the *move* rather than switched on here: only
/// `CompleteDelivery` answers `requiresSettledPayment`. Assigning, loading and
/// returning a parcel are things an operation does to a shipment and none of
/// them is the moment money changes hands.
///
/// **A payment status that cannot be read does not block the hand-over.** The
/// parcel is at the door and the courier is standing there; refusing over a
/// network would strand a delivery that has already happened. The collection
/// is reconciled afterwards — `payments`' own subscriber closes it when
/// `ShipmentDelivered` arrives — so the failure mode of guessing wrong here is
/// a debt to chase rather than a delivery that did not happen.
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
    required this._payments,
  });

  final ShipmentGateway _gateway;
  final ShipmentCache _cache;
  final Clock _clock;
  final DomainEventBus _events;
  final Logger _logger;
  final PaymentStatusReader _payments;

  @override
  Future<Result<Shipment, ShipmentFailure>> call(ShipmentMove move) async {
    if (move.requiresSettledPayment) {
      final owed = await _owedOn(move.id);
      if (owed != null) return Failed(owed);
    }

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

  /// The reason a hand-over must not be recorded, or `null` when there is
  /// none.
  ///
  /// Returns shipments' own failure, built from a string. `Money` is a
  /// payments type and section 2.1 keeps a foreign model out of shipments'
  /// vocabulary; what a caller here needs is a reason it can branch on and a
  /// sentence it can show, and `PaymentOutstanding` carries both without
  /// anybody downstream depending on payments to read it.
  Future<ShipmentFailure?> _owedOn(ShipmentId shipment) async {
    switch (await _payments.statusFor(shipment)) {
      case Failed(:final failure):
        // Deliberately not a refusal. The parcel is at the door; the
        // collection is reconciled afterwards, when the delivery event
        // reaches payments.
        _logger.warning(
          'completing a delivery without knowing what is owed',
          context: {'shipment': shipment.value, 'failure': '$failure'},
        );
        return null;
      case Success(value: Outstanding(:final amount)):
        return PaymentOutstanding(
          shipment: shipment.value,
          amount: '$amount',
        );
      case Success():
        return null;
    }
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
