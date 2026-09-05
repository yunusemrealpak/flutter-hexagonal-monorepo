import 'package:core_kernel/core_kernel.dart';

import '../values/shipment_id.dart';

/// A delivery was attempted and did not happen.
///
/// Published alongside the move to `ShipmentStatus.undeliverable`. See
/// `ShipmentDelivered` for why these events are hand-written and what
/// `occurredAt` means.
final class ShipmentFailed extends DomainEvent {
  /// Records the failed attempt on [shipmentId] at [occurredAt].
  const ShipmentFailed({
    required this.shipmentId,
    required this.reason,
    required super.occurredAt,
  });

  /// Which shipment.
  final ShipmentId shipmentId;

  /// Why it did not happen, in the operation's own words.
  ///
  /// A string rather than a code, because the taxonomy of why a delivery fails
  /// belongs to `delivery`, which owns `NonDeliveryReason`. A code here would
  /// be a second, quietly diverging copy of it — and it would have to be
  /// declared in this package, which would put delivery's vocabulary in
  /// shipments' contract.
  ///
  /// What a phrase means to whoever is listening is the listener's problem.
  /// `incidents_core` classifies it into its own `IncidentCategory` and is
  /// honest about the guess: anything it cannot place is `unclassified`.
  final String reason;

  @override
  String toString() => 'ShipmentFailed(${shipmentId.value}, $reason)';
}
