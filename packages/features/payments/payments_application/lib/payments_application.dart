/// The payments use cases: pure Dart, and blind to every adapter behind them.
///
/// Three things here are worth reading for the architecture rather than for
/// the feature.
///
/// **`CollectOnDelivery` binds the idempotency key to an intention, not to a
/// call.** It asks the gateway what it already has against the parcel first: a
/// settled attempt *is* the answer, an outstanding one lends its key, and only
/// an empty answer mints a new one. A use case that minted on every call would
/// produce a key per tap, and the far side would have no way to tell a retry
/// from a second charge.
///
/// **Cash may be recorded offline; a card may not.** An unreachable gateway
/// sends a cash collection to the outbox and lets it stand — the money is
/// already in the courier's hand and the server is only being told. A card
/// needs an acquirer to say yes, and reporting success without one would be
/// inventing money. That is a business rule, which is why it is here and not
/// in an adapter that could only see a timeout.
///
/// **`CollectionReconciler` is scenario 2 from the subscriber's side.** It
/// listens for `DeliveryCompleted` on the `DomainEventBus` port and closes the
/// matching cash collection. `delivery_application` never learns that anybody
/// listens; this package never learns who published. What the two share is one
/// type in `delivery_api` and a bus.
///
/// It is safe to run twice, and not by remembering what it has seen: the
/// gateway is idempotent by key, an already-settled collection is left alone,
/// and there is no collection at all on most parcels. Redelivery, a late
/// drain and a resubscribe on resume all cost nothing.
///
/// `PaymentsCoordinator` implements `PaymentsFacade` *and*
/// `PaymentStatusReader`. A composition root binds one object to both, and
/// `shipments_application` receives it as the reader — so it can ask what is
/// owed and cannot take money, because the type it holds has no method for it.
library;

export 'src/close_daily_settlement.dart';
export 'src/collect_on_delivery.dart';
export 'src/collect_payment_command.dart';
export 'src/collection_reconciler.dart';
export 'src/payment_status_of.dart';
export 'src/payments_coordinator.dart';
export 'src/refund_collection.dart';
