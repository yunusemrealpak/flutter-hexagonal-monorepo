# delivery_application

The delivery use cases. Pure Dart, and blind to every adapter that answers its ports.

## What it may depend on

`core_kernel`, `core_ports`, `delivery_api`, `identity_api`, `shipments_api`, `sync_api`

That list is section 2 of [`docs/DEPENDENCY_RULES.md`](../../../../docs/DEPENDENCY_RULES.md), one row. A dependency outside it is a violation rather than an exception; `dart run melos run arch:check` will say which rule and how to fix it.

`identity_api` and `shipments_api` are there for two identifiers — an attempt names the courier who made it and the parcel it was about. `sync_api` is scenario 3: this package depends on the queue's contract so that a completed delivery survives a basement, and `sync` depends on no feature at all.

## The order inside `CompleteWithProof`

The interesting part of this package is a sequence, not a class:

1. **Check the policy** — before anything is compressed or written. The entity checks again when it settles; doing it first means a high-value parcel closed without a photograph never costs a store write.
2. **Compress the photograph** — against a limit the composition root supplied, because what fits depends on what will carry it.
3. **Store the evidence**, and keep the handle. The bytes stop here.
4. **Queue the write** — not send it. A courier who has just handed over a parcel is not made to wait for a server.
5. **Publish `DeliveryCompleted`** — and only after the queue accepted the write. A subscriber closing a cash collection for a delivery that was never durably recorded would be reacting to something that did not happen.

Steps 4 and 5 are scenarios 3 and 2 respectively, in the same method.

## What must never live here

- **`delivery_infrastructure`, or any `platform/*`.** A use case that reached for one would stop being pure Dart and stop being testable without a device.
- **Another feature's `_application`.** `payments` reacts to `DeliveryCompleted` through the bus; this package does not know it exists.
- **`DateTime.now()`, `Random()` or `Uuid()`.** `Clock` and `IdGenerator` arrive through constructors — rules A1 and A3.
- **`flutter`.** Rule I2.

## Code generation

None. There is no `build.yaml` and no `build_runner` dependency — the cheapest configuration, not a missing one. `dart:convert` is used directly to build a command's payload, which is what `SyncCommand` asks of the feature that declares one: the body is *already serialised* by the time `sync` sees it.
