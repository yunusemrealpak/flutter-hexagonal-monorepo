import 'package:payments_api/payments_api.dart';
import 'package:shipments_api/shipments_api.dart';

/// What a courier can ask of the collection screen.
///
/// Sealed and hand-written, like the state beside it. Three cases, one per
/// thing a person at a door actually does: find out what is owed, choose how
/// it is being paid, hand the money over.
///
/// **The events exist so that the transformers can.** A `Cubit` would express
/// the same three operations as three methods and would be shorter; what it
/// could not express is *what happens when one arrives while another is still
/// running*. `CollectionSubmitted` is registered with `droppable()` and
/// `CollectionRequested` with `restartable()`, and neither policy has anywhere
/// to live without a value to attach it to. That is the whole trade, and it is
/// why the repository chose `Bloc` over `Cubit` rather than the other way
/// round — see `docs/ARCHITECTURE.md` §2.
sealed class CollectionEvent {
  const CollectionEvent();
}

/// Read what is owed on [shipment].
final class CollectionRequested extends CollectionEvent {
  /// Creates the event.
  const CollectionRequested(this.shipment);

  /// Which parcel the money is owed against.
  final ShipmentId shipment;
}

/// The courier is paying by [method].
final class MethodChosen extends CollectionEvent {
  /// Creates the event.
  const MethodChosen(this.method);

  /// Cash, card, or whatever else the operation accepts.
  final PaymentMethod method;
}

/// Take the money for [shipment].
final class CollectionSubmitted extends CollectionEvent {
  /// Creates the event.
  const CollectionSubmitted(this.shipment);

  /// Which parcel is being paid for.
  final ShipmentId shipment;
}
