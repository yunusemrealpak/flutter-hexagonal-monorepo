import 'package:core_kernel/core_kernel.dart';

import '../values/shipment_id.dart';

/// A shipment was handed to its consignee.
///
/// This is scenario 2 of the architecture in its declaration form.
/// `payments_application` closes a collection when a shipment is delivered; it
/// subscribes to this type through the `DomainEventBus` port in `core_ports`
/// and never depends on `shipments_application`. Neither package knows the
/// other exists. What they share is this file and a bus.
///
/// Hand-written rather than generated, and this time it is not a preference:
/// `DomainEvent` takes `occurredAt` through its constructor, and a `freezed`
/// union's generated subclass would have to call `super(...)` from a const
/// `._()` with nothing in scope to pass. The same constraint applies to
/// `Entity`, and it is the second half of why entities here are hand-written.
///
/// `occurredAt` is *domain* time — when the hand-over happened — not when the
/// event was published. The distinction matters the first time an event is
/// drained from an outbox two hours after the fact.
final class ShipmentDelivered extends DomainEvent {
  /// Records the hand-over of [shipmentId] at [occurredAt].
  const ShipmentDelivered({
    required this.shipmentId,
    required this.proofReference,
    required super.occurredAt,
  });

  /// Which shipment.
  final ShipmentId shipmentId;

  /// The proof `delivery` captured, by reference.
  ///
  /// A reference rather than the proof itself. A signature bitmap on an event
  /// bus is a signature bitmap in every subscriber's memory, and `payments`
  /// needs to know that proof exists, not what it looks like.
  final String proofReference;

  @override
  String toString() => 'ShipmentDelivered(${shipmentId.value}, at $occurredAt)';
}
