import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';
import 'package:shipments_api/shipments_api.dart';

/// A parcel was handed over and the evidence is stored.
///
/// **This is scenario 2 of the architecture in its declaration form.**
/// `delivery_application` publishes it on the `DomainEventBus` port in
/// `core_ports`; `payments_application` subscribes and closes the matching
/// cash collection. Neither `_application` package appears in the other's
/// pubspec and neither knows the other exists. What they share is this file
/// and a bus.
///
/// The subscriber therefore depends on `delivery_api` — a contract package,
/// which depends on no implementation, so the graph stays acyclic. That is the
/// whole trick, and it is the same one that makes scenario 1 work.
///
/// Hand-written rather than generated, and not out of preference:
/// `DomainEvent` takes `occurredAt` through its constructor, and a `freezed`
/// union's generated subclass would have to call `super(...)` from a const
/// `._()` with nothing in scope to pass.
///
/// [occurredAt] is *domain* time — when the hand-over happened — not when the
/// event was published. The distinction matters the first time an attempt is
/// drained from an outbox two hours after the fact.
final class DeliveryCompleted extends DomainEvent {
  /// Records the hand-over of [shipment] by [courier] at [occurredAt].
  const DeliveryCompleted({
    required this.shipment,
    required this.courier,
    required this.proofReference,
    required super.occurredAt,
  });

  /// Which parcel.
  final ShipmentId shipment;

  /// Who handed it over.
  final ActorId courier;

  /// Where the evidence is, as a plain string.
  ///
  /// A `String` rather than delivery's `ProofReference`, because a subscriber
  /// should not have to depend on this package's value objects to read an
  /// event it only forwards. `payments` needs to know that proof exists and
  /// to be able to quote the handle; it never resolves one.
  final String proofReference;

  @override
  String toString() =>
      'DeliveryCompleted(${shipment.value}, by ${courier.value}, '
      'at $occurredAt)';
}
