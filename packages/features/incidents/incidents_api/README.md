# incidents_api

The incidents contract: what an exception on a round is recorded as, when it escalates, and the port that keeps the record.

## `IncidentCategory` is not `NonDeliveryReason`

Delivery owns a union that answers *why a visit ended without a hand-over*. This feature owns an enum that answers *how fast somebody has to do something about it*. They overlap and are not the same question:

| | `NonDeliveryReason` (`delivery_api`) | `IncidentCategory` (here) |
|---|---|---|
| `rescheduled` | a first-class outcome | not an incident at all |
| `damagedInTransit` | an outcome with a required note | `damage`, which starts at `urgent` |
| a vehicle breakdown | not expressible | `fieldEmergency`, which starts at `critical` |

Borrowing delivery's union would have been borrowing a *model* — it carries a note, a requested date and a retry rule — which [`docs/DEPENDENCY_RULES.md`](../../../../docs/DEPENDENCY_RULES.md) §2.1 forbids, and it would have left this feature unable to record an exception with no delivery attempt behind it. Phase 5 learned that rule by rewriting `Stop`; this feature followed it on the first commit.

## Two identifiers cross, and both are nullable

`ShipmentId` because a vehicle breakdown concerns no parcel, and requiring one would force a caller to invent a shipment that every "incidents by shipment" report would then quietly include. `ActorId` because the product opens some incidents itself, from a `ShipmentFailed` event with no human at the other end — attributing that to whoever happened to be signed in would put a courier's name on a record they never made.

## `EscalationPolicy` is in the contract; settings' `ResolveLanguage` is not

Worth reading the two together, because they look like the same call and are not. A language bundle exists or does not exist in a *build*, so resolving against it is an implementation detail. How long a damaged parcel may sit before somebody is told is a rule of the *operation*, and a dispatcher's screen has to be able to say "escalates in four hours" without asking an implementation.

The policy takes `category` and the standard table ignores it. That parameter is on the signature because the first operation-specific rule anybody writes is "damage escalates faster than everything else", and adding a parameter later would be a breaking change to a contract three packages read.

## Escalation resets the age; that is what makes the sweep idempotent

`Incident.ageAt` measures from the last escalation when there has been one. A sweep that measured from the opening throughout would raise the same incident on every run, and a dispatcher's board would fill with movement nobody caused. Reaching the top severity succeeds and changes nothing, rather than failing — a sweep that reported an error for "already critical" would report errors for the incidents that need attention most.

## What it may depend on

`core_kernel`, `identity_api`, `shipments_api`

That list is section 2 of [`docs/DEPENDENCY_RULES.md`](../../../../docs/DEPENDENCY_RULES.md), one row. Two foreign `_api` packages, for two identifiers.

## What must never live here

- **`delivery_api`.** It is not needed, and needing it would mean a model had crossed.
- **An implementation of `IncidentLog` or `IncidentsFacade`.** Rule S8.
- **A DTO, or `json_annotation`.** Rules I4 and G2.
- **A rule that says which incidents a particular *build* can record.** That is a deployment fact; see the `EscalationPolicy` note above for the line.

## Code generation

None.
