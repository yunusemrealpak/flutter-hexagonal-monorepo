# payments_application

The payments use cases. Pure Dart, and blind to every adapter that answers its ports.

## What it may depend on

`core_kernel`, `core_ports`, `payments_api`, `delivery_api`, `identity_api`, `shipments_api`, `sync_api`

That list is section 2 of [`docs/DEPENDENCY_RULES.md`](../../../../docs/DEPENDENCY_RULES.md), one row. Four foreign `_api` packages, all contracts and none an implementation:

- **`delivery_api`** is scenario 2. `CollectionReconciler` subscribes to `DeliveryCompleted` through the `DomainEventBus` port. `delivery_application` is not here and never will be.
- **`shipments_api`** is scenario 1's first half. `shipments_application` will name `payments_api` in return; the graph stays acyclic because contracts depend on no implementation.
- **`sync_api`** is scenario 3 — a cash collection taken in a basement has to survive the basement.
- **`identity_api`** is one identifier.

## Three decisions worth reading

**The idempotency key is bound to an intention, not to a call.** `CollectOnDelivery` asks the gateway what it already has against the parcel first: a settled attempt *is* the answer, an outstanding one lends its key, and only an empty answer mints a new one from `IdGenerator`. A use case that minted on every call would produce a key per tap, and the far side would have no way to tell a retry from a second charge.

A *refusal* is different from a timeout, and the key is not reused after one. Idempotency protects against an uncertain outcome; a known refusal means nothing was taken, so a fresh intention is safe.

**Cash may be recorded offline; a card may not.** An unreachable gateway sends a cash collection to the outbox and lets it stand — the money is already in the courier's hand and the server is only being told. A card needs an acquirer to say yes, and reporting success without one would be inventing money. That is a business rule, which is why it lives here and not in an adapter that could only see a timeout.

**`CollectionReconciler` is safe to run twice, and not by remembering.** The gateway is idempotent by key, an already-settled collection is left alone, and most parcels have no collection at all. Redelivery, a late drain and a resubscribe on resume all cost nothing.

## What fails, and what does not

| Step | If it fails |
|---|---|
| Cash drawer accepts | the collection stops — a tally the courier cannot trust is worse than a collection that did not happen |
| Gateway refuses | the collection stops, and accepted cash is released |
| Gateway unreachable, cash | queued under `manualReview`, collection stands |
| Gateway unreachable, card | the collection stops |
| Receipt prints | logged; the collection stands |
| Settlement updates | logged; the collection stands |

The queue policy is the only `manualReview` in the workspace. Two records of one cash collection are either a double charge or a lost one, and neither is something a queue may decide on its own.

## What must never live here

- **`payments_infrastructure`, or any `platform/*`.**
- **`delivery_application`.** Payments hears about deliveries through a bus and one type.
- **`DateTime.now()`, `Random()` or `Uuid()`.** Rules A1–A3.
- **`flutter`.** Rule I2.

## Code generation

None. `dart:convert` is used directly to build a command's payload, which is what `SyncCommand` asks of the feature that declares one.
