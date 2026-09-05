import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:identity_api/identity_api.dart';

part 'shipment_status.freezed.dart';

/// Where a shipment is in its life, and what that state carries with it.
///
/// A closed union rather than an enum, because the states are not
/// interchangeable labels: an assigned shipment has a courier, a delivered one
/// has a proof and a moment, and an enum would force all three to live on the
/// shipment as nullable fields that are only meaningful in one state each.
/// That is the shape where `null` starts meaning four different things.
///
/// This is the union the specification asks to be expressed with `freezed`,
/// and the reason it is a good fit is the same one that makes it a bad fit for
/// entities: a state *is* its contents, so structural equality is correct.
/// What `freezed` does not express is which state may follow which — that
/// stays hand-written, in `Shipment`, because it is a rule rather than a
/// shape.
///
/// The case names are states, not events. `ShipmentDelivered` is a
/// `DomainEvent` published when a shipment reaches
/// [ShipmentDeliveredToConsignee]; naming both the same thing would make the
/// barrel export two unrelated types under one word.
@freezed
sealed class ShipmentStatus with _$ShipmentStatus {
  const ShipmentStatus._();

  /// Accepted into the operation, on nobody's manifest yet.
  const factory ShipmentStatus.awaitingAssignment() =
      ShipmentAwaitingAssignment;

  /// On a courier's manifest, still in the depot.
  const factory ShipmentStatus.assignedToCourier(ActorId courier) =
      ShipmentAssignedToCourier;

  /// Physically in the vehicle, scanned at loading.
  const factory ShipmentStatus.loadedOnVehicle(ActorId courier) =
      ShipmentLoadedOnVehicle;

  /// On the road, between the depot and the consignee.
  const factory ShipmentStatus.outForDelivery(ActorId courier) =
      ShipmentOutForDelivery;

  /// Handed over, with a reference to the proof that was captured.
  ///
  /// The proof itself belongs to `delivery` — a signature, a photograph, a
  /// scan. Shipments holds only the reference, because a shipment needs to
  /// know that proof exists and does not need to know what it looks like.
  const factory ShipmentStatus.deliveredToConsignee({
    required String proofReference,
    required DateTime at,
  }) = ShipmentDeliveredToConsignee;

  /// Attempted and not handed over.
  const factory ShipmentStatus.undeliverable({
    required String reason,
    required DateTime at,
  }) = ShipmentUndeliverable;

  /// Back in the depot, out of the delivery cycle.
  const factory ShipmentStatus.returnedToDepot({required DateTime at}) =
      ShipmentReturnedToDepot;

  /// The courier this shipment is currently on, where it is on one at all.
  ///
  /// A getter on the union rather than a field on `Shipment`, so that the
  /// answer cannot disagree with the state. A shipment that has been delivered
  /// is on nobody's manifest, and there is no way to spell the contradiction.
  ActorId? get courier => switch (this) {
    ShipmentAssignedToCourier(:final courier) => courier,
    ShipmentLoadedOnVehicle(:final courier) => courier,
    ShipmentOutForDelivery(:final courier) => courier,
    _ => null,
  };

  /// Whether no further transition is possible from here.
  bool get isTerminal => switch (this) {
    ShipmentDeliveredToConsignee() => true,
    ShipmentUndeliverable() => true,
    ShipmentReturnedToDepot() => true,
    _ => false,
  };

  /// A short, stable name for this state.
  ///
  /// Used in failure messages and in the transition table, so that the two
  /// cannot drift apart. Not for display: a screen localises the state, and a
  /// localisation key is not something a contract package should own.
  String get label => switch (this) {
    ShipmentAwaitingAssignment() => 'awaitingAssignment',
    ShipmentAssignedToCourier() => 'assignedToCourier',
    ShipmentLoadedOnVehicle() => 'loadedOnVehicle',
    ShipmentOutForDelivery() => 'outForDelivery',
    ShipmentDeliveredToConsignee() => 'deliveredToConsignee',
    ShipmentUndeliverable() => 'undeliverable',
    ShipmentReturnedToDepot() => 'returnedToDepot',
  };
}
