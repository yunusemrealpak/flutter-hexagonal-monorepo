# shipments_application

The shipments use cases. Pure Dart, and blind to every adapter that answers its ports.

## What is here, and what deliberately is not

| Here | Not here |
|---|---|
| read → apply → persist → publish | which state may follow which |
| the `Clock` the timestamp comes from | what a timestamp means |
| which port answers a question | how that port answers it |

The rule about which state may follow which lives in `Shipment`, in `shipments_api`. These use cases call it. A use case orchestrates and an entity decides, and when a rule starts appearing here it is a rule that two callers will eventually disagree about.

## Four use cases and a coordinator

| Class | Intention |
|---|---|
| `FindShipment` | read one, gateway first, cache only when the gateway could not be reached |
| `LoadManifest` | the rows a courier's stop list is drawn from |
| `ResolveBarcode` | turn a scan into a shipment, through two ports |
| `AdvanceShipment` | the one place a shipment's state changes and is written down |
| `ShipmentsCoordinator` | `ShipmentsFacade`, delegating to the four |

`AdvanceShipment` takes a sealed `ShipmentMove` rather than existing six times over. Each case knows which transition on `Shipment` it maps to and which domain event — if any — reaching that state is worth publishing. Six near-identical use cases would each read, transition, save, cache and publish, and the day the caching step changed, five would be updated and one forgotten.

**A move carries no timestamp.** The time comes from the `Clock` port inside the use case, so a caller cannot decide when a delivery happened. A facade that accepted a fully built `ShipmentStatus` would hand that decision back, and every test that wanted a delivery two hours ago could write one.

## Three decisions worth knowing about

**Gateway first, cache second — the opposite of "offline first".** A courier acts on a shipment's *current* state (may I deliver this?), and a stale answer would let them attempt a move the operation has already made impossible. So the cache answers only when the gateway could not.

**The fallback is narrow.** Only `ShipmentsUnavailable` falls through to the cache. A `ShipmentNotFound` is an answer, not a failure to answer, and serving a cached copy of a shipment the operation says does not exist is how a cancelled parcel gets delivered anyway.

**A failing cache is not a failing delivery.** `AdvanceShipment` saves to the gateway, then caches, and a cache failure is logged rather than returned. A shipment the operation has accepted is not un-accepted because this device could not write it to disk; failing there would turn a full disk into a delivery that did not happen.

## Known shortfall

An offline manifest is a subset. The cache holds the shipments this device has actually handled, so `LoadManifest`'s fallback returns what the courier had in hand rather than what the operation assigned them this morning. Closing that needs a sync that pulls a manifest ahead of time and an outbox that carries the moves back — `sync`'s job in phase 5. It is stated here rather than hidden behind an answer that looks complete.

## What it may depend on

Own `_api`, `core_kernel`, `core_ports`, and other features' `_api` packages.

## What must never live here

- **The Flutter SDK.** Rule I2. This is the fast majority of the test suite; a `ChangeNotifier` here would cost every one of those tests a binding.
- **Any `_infrastructure` package, or any `platform/*`.** A use case that could build an `HttpRequest` would eventually own a retry policy, and a retry policy is not a business rule. Only an app's composition root joins a use case to an adapter.
- **A service locator.** Every collaborator arrives through a constructor, so a constructor is the complete list of what a class can touch.
- **`DateTime.now()`.** Rule A1, and the reason a caller cannot forge a delivery time.
