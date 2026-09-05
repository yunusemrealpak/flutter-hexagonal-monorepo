import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';

import '../failures/shipment_failure.dart';
import '../values/barcode.dart';
import '../values/consignee.dart';
import '../values/shipment_id.dart';
import '../values/shipment_status.dart';
import '../values/status_transition.dart';

/// One parcel, and everything the operation knows about where it is.
///
/// This is the richest type in the workspace and the one the specification
/// singles out, because it is where the architecture either pays off or does
/// not. The state machine lives here — not in a use case, not in an adapter,
/// not in a screen — so that there is exactly one answer to "may this
/// shipment be delivered now?", and every driving adapter gets the same one.
///
/// An `Entity`, so equality is by [id]: a shipment that moved from `assigned`
/// to `loaded` is still the same shipment. That is also why it is hand-written
/// rather than generated; the reasoning is in this package's README.
final class Shipment extends Entity<ShipmentId> {
  /// Creates a shipment in a known state.
  ///
  /// Used by mappers in `shipments_infrastructure` to rebuild a shipment that
  /// already exists. New shipments come from [Shipment.accepted], which is the
  /// only entry point into the state machine.
  Shipment({
    required super.id,
    required this.barcode,
    required this.consignee,
    required this.status,
    required List<StatusTransition> history,
  }) : history = List<StatusTransition>.unmodifiable(history);

  /// Accepts a new shipment into the operation.
  ///
  /// Named for what happens rather than for the class, and it is not a
  /// constructor, because there is exactly one state a shipment may start in
  /// and a constructor that took a state would let a caller start one halfway
  /// through the machine.
  factory Shipment.accepted({
    required ShipmentId id,
    required Barcode barcode,
    required Consignee consignee,
  }) => Shipment(
    id: id,
    barcode: barcode,
    consignee: consignee,
    status: const ShipmentStatus.awaitingAssignment(),
    history: const [],
  );

  /// The number on the label.
  final Barcode barcode;

  /// Who receives it, and where.
  final Consignee consignee;

  /// Where it is now.
  final ShipmentStatus status;

  /// Every move it has made, oldest first, as an unmodifiable list.
  final List<StatusTransition> history;

  /// Which state may follow which.
  ///
  /// The specification's chain, written once:
  ///
  /// ```text
  /// awaitingAssignment -> assignedToCourier -> loadedOnVehicle
  ///   -> outForDelivery -> deliveredToConsignee | undeliverable
  ///                      | returnedToDepot
  /// ```
  ///
  /// A table rather than a chain of `if`s in six methods. The methods below
  /// build the target state and say who is asking; whether the move is legal
  /// is answered here, in one place that a test can read against the diagram
  /// above.
  ///
  /// A real operation would add one row on its first bad week — a second
  /// attempt after `undeliverable`, which is `undeliverable -> outForDelivery`
  /// — and it is left out because the specification's machine is what this
  /// package exists to demonstrate. Adding it is one entry; that it is one
  /// entry is the point of the table.
  static bool _allows(ShipmentStatus from, ShipmentStatus to) =>
      switch ((from, to)) {
        (ShipmentAwaitingAssignment(), ShipmentAssignedToCourier()) => true,
        (ShipmentAssignedToCourier(), ShipmentLoadedOnVehicle()) => true,
        (ShipmentLoadedOnVehicle(), ShipmentOutForDelivery()) => true,
        (ShipmentOutForDelivery(), ShipmentDeliveredToConsignee()) => true,
        (ShipmentOutForDelivery(), ShipmentUndeliverable()) => true,
        (ShipmentOutForDelivery(), ShipmentReturnedToDepot()) => true,
        _ => false,
      };

  /// Puts this shipment on [courier]'s manifest.
  Result<Shipment, ShipmentFailure> assignTo(
    ActorId courier, {
    required DateTime at,
  }) => _moveTo(ShipmentStatus.assignedToCourier(courier), at: at, by: courier);

  /// Records that [courier] scanned it into the vehicle.
  Result<Shipment, ShipmentFailure> loadOnto(
    ActorId courier, {
    required DateTime at,
  }) => _requireAssignedCourier(courier).flatMap(
    (_) => _moveTo(
      ShipmentStatus.loadedOnVehicle(courier),
      at: at,
      by: courier,
    ),
  );

  /// Records that [courier] left the depot with it.
  Result<Shipment, ShipmentFailure> startDelivery(
    ActorId courier, {
    required DateTime at,
  }) => _requireAssignedCourier(courier).flatMap(
    (_) => _moveTo(
      ShipmentStatus.outForDelivery(courier),
      at: at,
      by: courier,
    ),
  );

  /// Records a hand-over, against the proof `delivery` captured.
  Result<Shipment, ShipmentFailure> completeDelivery({
    required String proofReference,
    required DateTime at,
  }) {
    if (proofReference.trim().isEmpty) {
      return const Failed(
        MalformedValue(field: 'proofReference', reason: 'is empty'),
      );
    }
    return _moveTo(
      ShipmentStatus.deliveredToConsignee(
        proofReference: proofReference.trim(),
        at: at,
      ),
      at: at,
      by: status.courier,
    );
  }

  /// Records an attempt that did not result in a hand-over.
  Result<Shipment, ShipmentFailure> failDelivery({
    required String reason,
    required DateTime at,
  }) {
    if (reason.trim().isEmpty) {
      return const Failed(
        MalformedValue(field: 'reason', reason: 'is empty'),
      );
    }
    return _moveTo(
      ShipmentStatus.undeliverable(reason: reason.trim(), at: at),
      at: at,
      by: status.courier,
    );
  }

  /// Records that it came back to the depot.
  ///
  /// [by] is optional because this is the one move the system makes on its
  /// own: the end-of-shift sweep has no actor, and inventing one would make
  /// the audit trail lie.
  Result<Shipment, ShipmentFailure> returnToDepot({
    required DateTime at,
    ActorId? by,
  }) => _moveTo(
    ShipmentStatus.returnedToDepot(at: at),
    at: at,
    by: by,
  );

  /// Applies [next] if the machine allows it, recording the move.
  Result<Shipment, ShipmentFailure> _moveTo(
    ShipmentStatus next, {
    required DateTime at,
    ActorId? by,
  }) {
    if (!_allows(status, next)) {
      return Failed(status.cannotBecome(next));
    }
    return Success(
      Shipment(
        id: id,
        barcode: barcode,
        consignee: consignee,
        status: next,
        history: [
          ...history,
          StatusTransition(from: status, to: next, at: at, by: by),
        ],
      ),
    );
  }

  /// Refuses a move asked for by somebody other than the assigned courier.
  ///
  /// Separate from the transition table because it is a different question.
  /// The table answers "is this move legal from here?"; this answers "is this
  /// person the one who may make it?", and reporting the second as the first
  /// would tell a courier who scanned a colleague's parcel that the parcel is
  /// in the wrong state.
  Result<void, ShipmentFailure> _requireAssignedCourier(ActorId courier) {
    final assigned = status.courier;
    if (assigned != null && assigned != courier) {
      return Failed(
        NotTheAssignedCourier(assigned: assigned, attempted: courier),
      );
    }
    return const Success(null);
  }

  /// Returns a copy with the given fields replaced.
  ///
  /// [status] is deliberately absent. Changing the state is what the
  /// transition methods are for, and a `copyWith(status: …)` would be a way
  /// around the entire state machine that looked like ordinary code.
  Shipment copyWith({Barcode? barcode, Consignee? consignee}) => Shipment(
    id: id,
    barcode: barcode ?? this.barcode,
    consignee: consignee ?? this.consignee,
    status: status,
    history: history,
  );

  @override
  String toString() => 'Shipment(${id.value}, ${status.label})';
}
