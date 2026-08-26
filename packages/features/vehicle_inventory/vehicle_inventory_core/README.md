# vehicle_inventory_core

The vehicle inventory use cases, the store that keeps a count, and two answers to one manifest port.

## Scenario 4, at the smallest scale the workspace has it

`HttpManifestSource` asks the depot's backend. `CachedManifestSource` wraps another source, asks it first, and remembers what it said. Neither is visible from a use case — `StartCount` holds `ManifestSource` — and which one an app builds is a composition-root decision.

Here the two **compose** rather than compete, which is the shape offline behaviour usually takes. A depot basement has no signal, and that is the whole reason the cache exists: a feature that shipped only the HTTP adapter would pass every test and fail every morning.

Two decisions inside the cache are worth naming:

- **The fallback is silent.** A courier who cannot start counting because the server is slow is a courier standing next to a van they could be loading. What staleness costs is a manifest a few hours old, and the count itself is what discovers the difference.
- **A cache that cannot be written does not fail the call.** A manifest that arrived is still the answer. Failing because the *cache* failed would turn a working morning into a broken one.

## Raw identifiers become typed ones in the use case

`ManifestSource` answers with `List<String>` so that its adapters need not see `shipments_api`. `StartCount` parses them, and a manifest carrying something that is not a shipment identifier fails the count rather than dropping the entry. A dropped entry is a parcel nobody counts and nobody misses.

`HttpManifestSource` *could* build `ShipmentId`s — a `_core` package may see a foreign `_api` — and does not, because the port promises strings and an adapter that produced typed identifiers could not move into an `_infrastructure` package the day this feature is split.

## Every transport failure collapses to one

`ManifestUnavailable`, whatever the transport said. Not laziness: there is exactly one thing a caller can do about any of them, which is fall back to the cache. Splitting them would invite a caller to treat a timeout differently from a 500 for no reason it could act on.

## Closing logs, and refuses nothing

`LoadCount` allows a count to close with a discrepancy, and that is right. `CloseCount` writes a warning when it happens, because a missing parcel whose only trace is a record somebody has to go looking for is a missing parcel nobody looks for.

## What it may depend on

`core_kernel`, `core_ports`, `vehicle_inventory_api`, `identity_api`, `shipments_api`, `http_dio`

That list is section 2 of [`docs/DEPENDENCY_RULES.md`](../../../../docs/DEPENDENCY_RULES.md), one row. `http_dio` brings no Flutter SDK with it, so this package still runs under `dart test` — unlike `notifications_core`, which reaches a device through `push_messaging` and does not.

## What must never live here

- **An import between the two halves.** The three adapters import no use case; no use case imports them.
- **`DateTime.now()` or `Random()`.** Rules A1 and A3.
- **A second implementation of the missing/unexpected arithmetic.** It is on `LoadCount`.
- **A retry policy in a use case.** Retries belong to the transport adapter, which is where `HttpTransport` lives.

## Code generation

None. `LoadCountDto` is seven fields and a hand-written codec.
