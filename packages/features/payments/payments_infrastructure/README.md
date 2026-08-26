# payments_infrastructure

The payments adapters: the gateway, the device copy that makes it work in a tunnel, the day's store, the drawer, and the mappers between them.

## What it may depend on

`core_kernel`, `core_ports`, `payments_api`, `http_dio`, `json_annotation`

That list is section 2 of [`docs/DEPENDENCY_RULES.md`](../../../../docs/DEPENDENCY_RULES.md), one row. **No foreign feature appears in it.** The mapper still has to rebuild the `ActorId` and `ShipmentId` payments' contract is expressed in, and it does so through `CourierReference` and `ShipmentReference` — readers published by `payments_api`, the one layer allowed to see those packages.

No platform package brings the Flutter SDK in here, which is why this package's tests run under `dart test` while `delivery_infrastructure`'s run under `flutter test`. Money is an HTTP request and a row; delivery needed a camera and a position, and paid for them.

## `DeviceBackedPaymentsGateway` is what makes offline idempotency real

`CollectOnDelivery` asks `attemptFor` before it mints a key, so that two taps on one intention produce one key. Against a bare `RestPaymentsGateway` that check is worthless in a tunnel: the read fails, the use case mints again, and the courier's second tap queues a second collection.

With this decorator in front, the read is answered from what *this device* recorded. It writes locally after the remote agrees **and** when the remote cannot be reached — the local copy is what the device knows, whether or not anybody else knows it yet. A refusal is not written down: recording it would make the next tap find an intention the server has on file as declined. A refund has no offline path at all, for the same reason `RefundCollection` has none.

It is a decorator rather than a base class, so it composes with whatever answers the remote side — `app_harness` puts a fake behind it and gets the same offline behaviour with no second implementation to keep in step. The contract kit runs against it and against the bare REST adapter, and the fact that nothing in the kit changes is the assertion that matters: it adds an offline *answer*, not a different contract.

## `RestPaymentsGateway` carries the key in the URL

`collect` is a `PUT` to the attempt's own key rather than a `POST` to a collection. A resend after a lost acknowledgement is then the same request rather than a second charge — an adapter that posted would have to hope the server read a header.

A refusal is read out of the rejected response, with the far side's own reason where it gave one, because a courier at a door has to be able to say why. Everything else is `PaymentsUnavailable`, and `CollectOnDelivery` decides whether that is survivable: cash yes, card no.

## `KeyValueReceiptPrinter` does not drive a printer

There is no printer among the eight platform packages phase 2 fixed, and a courier platform's receipt is usually a screen or a message. The port exists for something this small because "was a receipt produced" is a question a regulator asks, the answer needs a seam a test can watch, and the technology behind it is somebody else's decision. An operation with a bluetooth roll printer binds a different adapter and nothing else moves.

## What must never live here

- **`payments_application`.** Only an app's composition root joins the two.
- **Any foreign feature, contract included.**
- **A decimal amount.** Minor units and a currency code cross every boundary here; a JSON number is a double in most parsers, and a settlement rebuilt from doubles is off by an amount somebody has to explain.
- **A full card number.** `last4` is what crosses, and only because a customer recognises it on a receipt.
- **A rule about whether money may move.** That is `PaymentAttempt`'s and `CollectOnDelivery`'s. These adapters report facts.

## Code generation

`json_serializable` only, narrowed to `lib/src/**.dart` — rule G4.
