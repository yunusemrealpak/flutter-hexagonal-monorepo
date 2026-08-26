# incidents_core

The incidents use cases, the log that answers them, and the watcher that opens an incident when a shipment reports that it failed.

## `ShipmentFailureWatcher` is scenario 2 in a light feature

`shipments_application` publishes `ShipmentFailed` and has never heard of incidents. This package subscribes and has never heard of `shipments_application`. Both know only the `DomainEventBus` port in `core_ports` and a `DomainEvent` subtype in an `_api` package they both already read.

The trade is worth restating, because this is the third time the workspace takes it: **events buy decoupling and cost traceability.** Nothing in `shipments` says that a failed delivery opens an incident, and finding that out means searching for subscribers. It is the right trade here — an operation that stopped recording incidents would change this file and nothing in the feature that produces the event.

`start()` returns the subscription rather than keeping it, so whoever started the watcher is the one that can stop it. A watcher that owned its own subscription would need a `dispose` a composition root had to remember, and forgetting it would leave a second watcher opening every incident twice after a sign-out and back in.

## `ReasonClassifier` is why the event carries a `String`

`ShipmentFailed.reason` is free text, and that is not an oversight in `shipments_api`: the taxonomy of why a delivery failed belongs to `delivery`, and an enum on the event would have been a second copy of `NonDeliveryReason` quietly diverging from it. What crosses the bus is an identifier and a phrase — exactly as much as an unrelated feature should be able to depend on.

The classification is therefore a guess and says so. Anything it cannot place becomes `unclassified` rather than the nearest plausible category, because a wrong category is worse than an honest "other": it is invisible in a report, and somebody counting damage claims would count a locked gate among them and never know.

**Every phrase in the table is written lower-cased, and Turkish is why that is worth saying.** Matching folds incoming text with `toLowerCase`, which is locale-independent in Dart: `ı` upper-cases to `I` and lower-cases back to `i`, so a key written `ALICI` would never match the `alıcı` an operation actually types.

## `IncidentDto` is the one place a foreign identifier is rebuilt

`ActorId.parse` and `ShipmentId.parse` are called there, and both return *their own* feature's failure type — so the mapping ends in a `mapFailure` that translates into `IncidentsFailure`. An `_infrastructure` package could not do this at all: it may not see a foreign `_api`, and would need a reader published by its own contract, the way `shipments_api` publishes `CourierReference`. A `_core` package may. The difference is worth knowing before this feature is ever split, because it is the one place where the move would not be a pure `git mv`.

## The entity refuses; the use cases do not repeat it

`Incident.opened` insists on a note for damage; `Incident.resolvedAtInstant` refuses a second closing and an empty account. `ReportIncident` and `ResolveIncident` do not check either. A rule enforced in two places is a rule that will disagree with itself, and the copy in the use case is the one an adapter can bypass.

## What it may depend on

`core_kernel`, `core_ports`, `incidents_api`, `identity_api`, `shipments_api`

That list is section 2 of [`docs/DEPENDENCY_RULES.md`](../../../../docs/DEPENDENCY_RULES.md), one row. No `platform/*`: this feature reaches storage through `KeyValueStore`, a port.

## What must never live here

- **An import between the two halves.** `KeyValueIncidentLog` and `IncidentDto` import no use case; no use case imports them.
- **`delivery_api`.** The watcher reads a phrase, not a `NonDeliveryReason`.
- **`DateTime.now()` or `Random()`.** Rules A1 and A3 — and every interesting rule in this package is about time.
- **A second copy of a rule that lives on `Incident`.**

## Code generation

None. `IncidentDto` is ten fields and a hand-written codec, and `json_serializable` is permitted on this row the day the shape stops being pleasant to read.
