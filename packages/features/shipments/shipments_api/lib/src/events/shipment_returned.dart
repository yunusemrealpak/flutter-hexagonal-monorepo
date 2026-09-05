import 'package:core_kernel/core_kernel.dart';

import '../values/shipment_id.dart';

/// A shipment came back to the depot.
///
/// See `ShipmentDelivered` for why these events are hand-written and what
/// `occurredAt` means.
final class ShipmentReturned extends DomainEvent {
  /// Records the return of [shipmentId] at [occurredAt].
  const ShipmentReturned({
    required this.shipmentId,
    required super.occurredAt,
  });

  /// Which shipment.
  final ShipmentId shipmentId;

  @override
  String toString() => 'ShipmentReturned(${shipmentId.value}, at $occurredAt)';
}
