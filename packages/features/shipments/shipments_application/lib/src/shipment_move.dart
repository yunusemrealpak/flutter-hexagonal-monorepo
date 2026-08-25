import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';
import 'package:shipments_api/shipments_api.dart';

/// One thing a caller wants to do to a shipment's state.
///
/// Sealed, and each case knows two things: which transition on `Shipment` it
/// corresponds to, and which domain event — if any — reaching that state is
/// worth telling the rest of the product about.
///
/// This is what lets `AdvanceShipment` be one use case instead of six
/// near-identical ones. The six would each read the shipment, call one
/// transition, save, cache and publish, and the day the caching step changed
/// five of them would be updated and one forgotten.
///
/// Crucially, a move carries **no timestamp**. The time comes from the `Clock`
/// port inside the use case, so a caller cannot decide when a delivery
/// happened. A `ShipmentsFacade` that accepted a fully built `ShipmentStatus`
/// would hand that decision back, and every test that wanted a delivery two
/// hours ago could write one.
sealed class ShipmentMove {
  const ShipmentMove();

  /// Which shipment this move is about.
  ShipmentId get id;

  /// Applies the move, at the instant the use case read from the clock.
  Result<Shipment, ShipmentFailure> applyTo(Shipment shipment, DateTime now);

  /// What the rest of the product should hear about, if anything.
  ///
  /// `null` for the moves nobody outside shipments cares about. An event per
  /// transition would be a bus carrying six times the traffic for the sake of
  /// symmetry, and a subscriber filtering five of them out.
  DomainEvent? eventFor(Shipment moved, DateTime now);
}

/// Put the shipment on a courier's manifest.
final class AssignToCourier extends ShipmentMove {
  /// Creates the move.
  const AssignToCourier({required this.id, required this.courier});

  @override
  final ShipmentId id;

  /// Whose manifest.
  final ActorId courier;

  @override
  Result<Shipment, ShipmentFailure> applyTo(Shipment shipment, DateTime now) =>
      shipment.assignTo(courier, at: now);

  @override
  DomainEvent? eventFor(Shipment moved, DateTime now) => null;
}

/// Record that a courier scanned the shipment into their vehicle.
final class LoadOntoVehicle extends ShipmentMove {
  /// Creates the move.
  const LoadOntoVehicle({required this.id, required this.courier});

  @override
  final ShipmentId id;

  /// Who scanned it.
  final ActorId courier;

  @override
  Result<Shipment, ShipmentFailure> applyTo(Shipment shipment, DateTime now) =>
      shipment.loadOnto(courier, at: now);

  @override
  DomainEvent? eventFor(Shipment moved, DateTime now) => null;
}

/// Record that a courier left the depot with the shipment.
final class StartDelivery extends ShipmentMove {
  /// Creates the move.
  const StartDelivery({required this.id, required this.courier});

  @override
  final ShipmentId id;

  /// Who left with it.
  final ActorId courier;

  @override
  Result<Shipment, ShipmentFailure> applyTo(Shipment shipment, DateTime now) =>
      shipment.startDelivery(courier, at: now);

  @override
  DomainEvent? eventFor(Shipment moved, DateTime now) => null;
}

/// Record a hand-over against the proof `delivery` captured.
final class CompleteDelivery extends ShipmentMove {
  /// Creates the move.
  const CompleteDelivery({required this.id, required this.proofReference});

  @override
  final ShipmentId id;

  /// The proof, by reference.
  final String proofReference;

  @override
  Result<Shipment, ShipmentFailure> applyTo(Shipment shipment, DateTime now) =>
      shipment.completeDelivery(proofReference: proofReference, at: now);

  /// Publishes `ShipmentDelivered`.
  ///
  /// This is scenario 2 of the architecture at the point where it happens.
  /// `payments_application` closes the matching collection when it sees this
  /// event, and the two packages never learn of each other: both know only the
  /// `DomainEventBus` port in `core_ports` and the event type in
  /// `shipments_api`.
  @override
  DomainEvent? eventFor(Shipment moved, DateTime now) => ShipmentDelivered(
    shipmentId: moved.id,
    proofReference: proofReference,
    occurredAt: now,
  );
}

/// Record an attempt that did not result in a hand-over.
final class FailDelivery extends ShipmentMove {
  /// Creates the move.
  const FailDelivery({required this.id, required this.reason});

  @override
  final ShipmentId id;

  /// Why it did not happen.
  final String reason;

  @override
  Result<Shipment, ShipmentFailure> applyTo(Shipment shipment, DateTime now) =>
      shipment.failDelivery(reason: reason, at: now);

  @override
  DomainEvent? eventFor(Shipment moved, DateTime now) => ShipmentFailed(
    shipmentId: moved.id,
    reason: reason,
    occurredAt: now,
  );
}

/// Record that the shipment came back to the depot.
final class ReturnToDepot extends ShipmentMove {
  /// Creates the move.
  const ReturnToDepot({required this.id, this.by});

  @override
  final ShipmentId id;

  /// Who brought it back, where a person did.
  final ActorId? by;

  @override
  Result<Shipment, ShipmentFailure> applyTo(Shipment shipment, DateTime now) =>
      shipment.returnToDepot(at: now, by: by);

  @override
  DomainEvent? eventFor(Shipment moved, DateTime now) =>
      ShipmentReturned(shipmentId: moved.id, occurredAt: now);
}
