# delivery_infrastructure

The delivery adapters: two answers to the proof store, the gateway, the geofence, and the mappers between them.

## What it may depend on

`core_kernel`, `core_ports`, `delivery_api`, `http_dio`, `location_service`, `json_annotation`

That list is section 2 of [`docs/DEPENDENCY_RULES.md`](../../../../docs/DEPENDENCY_RULES.md), one row. A dependency outside it is a violation rather than an exception; `dart run melos run arch:check` will say which rule and how to fix it.

**No foreign feature appears in it**, which is the row for `feature_infrastructure`. The mapper still has to rebuild the `ActorId` and `ShipmentId` delivery's contract is expressed in, and it does so through `CourierReference` and `ShipmentReference` — readers published by `delivery_api`, the one layer allowed to see those packages. That is also why `HttpGeoFence` asks *delivery's* endpoint where a parcel is going rather than asking `shipments`: it could not ask, even in principle.

## Two adapters, one port

| Port | `app_courier` | `app_dispatcher` | `app_harness` |
|---|---|---|---|
| `ProofStorePort` | `LocalEncryptedProofStore` | `RemoteProofStore` | `FakeProofStore` |

All three pass `runProofStoreContract` from `delivery_testing`. A signature captured in a basement has to be kept on the device; an operator's machine has no business holding a thousand couriers' photographs. Nothing in `delivery_application` can tell which one answered.

## Where the "encrypted" in `LocalEncryptedProofStore` comes from

Not from that file: there is no cipher in it, and inventing one would be worse than not having one. The `KeyValueStore` a composition root binds under it is drift-backed, and the database is opened with a passphrase the app reads from `SecureStore` — which is exactly what that port reserves itself for, secrets rather than payloads. Encryption at rest is a property of the store beneath the adapter; putting it in the adapter would mean every adapter that persists anything re-implementing it.

`KeyValueStore`'s own documentation warns against persisting domain data through it, and the warning is about features that skip designing a repository. This is the repository: `ProofStorePort` is delivery's own outbound port, typed and versioned, and the key-value store is the byte bucket underneath. `routing`'s cache is built the same way.

## Why `BudgetMediaCompressor` does not re-encode

The cheapest place to make a photograph small is the camera: `MediaCapture.capturePhoto` takes `maxWidthPixels` and `quality`, and downscaling at capture costs nothing because the pixels were never allocated. Re-encoding afterwards means decoding a JPEG, resampling and encoding again — an image library, on a device already holding a day's queue.

So this adapter is the *decision* half of the port: does it fit, and what happens if not. `MediaTooLarge` sends the courier back to the camera rather than leaving an entry stuck in an outbox on a device with no signal. An app that acquires an image library binds a different adapter here and nothing else in the feature moves.

## Reading an attempt back replays its transitions

`DeliveryMapper` has no hydrating constructor to call: a stored attempt is started and then completed or failed, exactly as it happened the first time. That costs a few lines and buys the guarantee that no shape this package produces is one the domain could not have produced — including the proof policy, so a stored high-value proof that has lost its photograph fails to load instead of quietly becoming a valid delivery.

## What must never live here

- **`delivery_application`.** Rule row `feature_infrastructure`. Only an app's composition root joins the two.
- **Any foreign feature, contract included.**
- **A retry policy for a queued write.** `sync` retries on a schedule that knows how many times an entry has already been tried; an adapter that retried on its own would multiply the two.
- **A business rule.** Whether a proof is sufficient is `ProofPolicy`'s; whether a distance is acceptable is `StartAttempt`'s. This package reports facts.

## Code generation

`json_serializable` only, narrowed to `lib/src/**.dart` — rule G4. `freezed` is absent rather than disabled: it is not a dev dependency here, so naming it would fail the build instead of tightening it.

## Tests

This package depends on the Flutter SDK transitively through `location_service`, so its tests run under `flutter test` rather than `dart test`. The pure Dart half of the feature — `delivery_api` and `delivery_application`, where the rules live — is untouched by that.
