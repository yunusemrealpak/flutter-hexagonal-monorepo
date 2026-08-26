# reporting_core

The reporting use cases, the store behind the running totals, and the watcher that builds them from what other features publish.

## A read model, and a different use of the bus from `incidents`

`shipments_application` publishes `ShipmentDelivered`, `ShipmentFailed` and `ShipmentReturned` and has never heard of reporting. This package subscribes and has never heard of `shipments_application`. Both know only the `DomainEventBus` port and three `DomainEvent` subtypes in an `_api` they already read.

The difference from `incidents` is worth naming, because they use the same mechanism for different ends:

| | `incidents` | `reporting` |
|---|---|---|
| On an event | creates a new thing in the world | moves a number |
| Owns | a record somebody acts on | the numbers, and nothing else |
| Facade | reports, escalates, resolves | reads only |

That is why `ReportingFacade` has no write on it: there is no way to tell reporting that something happened except by it happening.

Three subscriptions rather than one over `DomainEvent`, because `DomainEventBus.on<T>()` is typed and one subscription would have to re-discover the type with a `switch` the compiler could not check.

## Nothing here asks what time it is

Every instant arrives on an event, and a day is attributed by **domain time**. A tally attributed by processing time would move a delivery into today because a phone was switched on this morning, and yesterday's total would change after somebody had already read it.

`RecordOutcome` therefore has no `Clock` in its constructor, which is the shortest way to prove the property.

## A failed write is logged, and the watcher stays alive

There is nobody to return it to. A read model that stopped counting on the first locked write would show a dispatcher a plausible number that had quietly stopped moving — worse than one that is obviously broken.

## A range includes its empty days

A chart with a gap where Sunday should be reads as missing data and sends somebody looking for a synchronisation problem. A Sunday with zero on it reads as a Sunday. The days are walked in UTC — the same arithmetic `ReportingDay.of` uses — so a range never skips or repeats a day at a daylight-saving boundary the way local-time addition does.

An inverted range is refused rather than answered with nothing: a dispatcher can produce one from a date picker in a single tap.

## What it may depend on

`core_kernel`, `core_ports`, `reporting_api`, `shipments_api`

That list is section 2 of [`docs/DEPENDENCY_RULES.md`](../../../../docs/DEPENDENCY_RULES.md), one row. No `platform/*`: the totals reach the disk through `KeyValueStore`, a port.

## What must never live here

- **An import between the two halves.** `KeyValueTallyStore` and `TallyDto` import no use case; no use case imports them.
- **A `Clock`.** See above — its absence is the proof.
- **`shipments_application`.** The events are in `shipments_api`; the arrow points from here to there and never back.
- **A stored count.** `TallyDto` stores outcomes for the same reason the entity holds them.

## Code generation

None.
