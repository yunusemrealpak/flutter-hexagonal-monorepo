# routing_api

A courier's route, the order it is driven in, and the times that follow from that order.

## The port this package exists for

`RouteOptimizerPort` is scenario 4 of the specification. Two implementations ship, and both pass one contract kit:

| Implementation | Where it runs | Which app binds it | Why |
|---|---|---|---|
| `LocalHeuristicOptimizer` | on the device | `app_courier` | a courier in a dead zone still has to be given an order to drive |
| `RemoteSolverOptimizer` | on a server | `app_dispatcher` | an operator planning forty routes at eight in the morning has a connection and needs answers a phone cannot compute |
| `FakeRouteOptimizer` | in a test | `app_harness` | — |

Not one line of `routing_application` changes between them.

## Why an optimiser returns a permutation and nothing else

This is the decision that makes the contract writable.

`RouteOptimizerPort.optimise` returns a `StopSequence` — an order, and only an order. The estimates are computed by `RoutePlan`, from that order plus the traffic profile plus the service times.

Two things follow:

**The kit can compare answers.** Orderings are exactly comparable. Instants are not: two implementations would round differently on the first Tuesday, and no suite could tell a better answer from a wrong one.

**A business rule stays out of a solver.** *"Arrival, plus any wait for the window, plus the service time"* is a fact about how this operation works, not about how a solver works. A remote solver written by another team would otherwise be free to disagree with it — and would, eventually.

## Why the traffic profile is in the request

`RemoteSolverOptimizer` could ask a traffic service itself. `LocalHeuristicOptimizer` could not. **A port whose two implementations see different inputs is a port whose contract cannot be written down.**

So a use case fetches the profile through `TrafficDataPort` and hands the same number to whichever optimiser is bound. `TrafficProfile` is coarse on purpose — one speed and one congestion multiplier, not a per-edge matrix — because a matrix is a shape only one of the two could ever fill.

The honest consequence: ETAs from this feature are good enough to order stops and to tell a courier roughly when they will be somewhere. They are not good enough to promise a customer a fifteen-minute slot, and nothing here pretends otherwise.

## Why time windows are on the stop, not in the constraints

A window is a fact about the *place* — a pharmacy closes at six whoever is driving. Putting it on `Stop` means every optimiser sees it whether or not anybody asked.

A window that travelled as a `RouteConstraint` could be omitted by the caller and silently ignored by the implementation, which is the failure mode where a pharmacy closes at six and the route arrives at half past.

## What crosses to another feature, and what does not

This package names `ActorId` and `ShipmentId` — and nothing else of theirs. That is section 2.1's rule, which the wider literature states as *reference other bounded contexts by identity*: **an identifier crosses, a model does not.**

`Stop` is where the repository learned it the expensive way. It used to hold shipments' `AddressPoint`: three fields, a validation and a display string — a concept `shipments` owns, answering *"where is this parcel going"*. Routing's question is *"what point do I measure from"*, and the answer to that is its own `GeoPoint`.

Carrying the foreign model cost three things at once, and only the last one looked like a rule problem:

| Symptom | Where it showed up |
|---|---|
| Every stop had to answer *"do you have coordinates?"* on every read | `Stop.placed` returned a `Result` |
| `StopNotGeocoded` sat in the contract three optimisers are held to | `runRouteOptimizerContract` had a case for it |
| `routing_infrastructure` could not build a stop without `shipments_api` | `arch_check: forbidden_dependency` |

Replacing it with `GeoPoint` + a plain `label` removed all three. `Stop.place` is now the only constructor, so the check happens **once, at the boundary** — and a stop without coordinates became unconstructible rather than merely reported.

`CourierReference` and `ShipmentReference` are the other half. They read a foreign identifier and report a bad one as a *routing* failure, so `routing_infrastructure` — which may see no foreign feature at all — can rebuild the identifiers this contract is expressed in without depending on the packages that declare them. Same shape as `CourierReference` in `shipments_api`, which has been doing this since phase 4.

## `ConstraintUnsatisfiable` reports instead of relaxing

An optimiser that quietly truncated a route to fit `maxStops` would be deciding which four parcels are not delivered today. That is not a decision this layer is entitled to make.

## Why `GeoPoint` is not `GeoFix`

`platform/location_service` publishes a `GeoFix`: an accuracy radius, the moment the device fixed it, and a permission that may have been denied. That is what a *device reported*.

A `GeoPoint` is a *place*: two coordinates and a validating factory, because a latitude of 91 is not somewhere a courier can be sent. `routing_infrastructure` maps one into the other, which is the same DTO-to-entity discipline rule 1.2.10 asks for at every boundary.

`distanceTo` lives on `GeoPoint` rather than in an optimiser, because both implementations need it and neither should own it. Two haversines eventually disagree about the length of the same route — and that is drift a contract kit *cannot* catch, since both answers would still satisfy the port.

It is also the type `Stop` holds, which is the point above: routing measures from a place it owns, not from an address another feature owns.

## Where the line around code generation is drawn

| Shape | How | Why |
|---|---|---|
| `RoutingFailure`, `RouteConstraint` | `freezed` | Closed unions of small values. |
| `Eta`, `OptimisationRequest` | `freezed` | Records. No identity, nothing to validate. |
| `RoutePlan`, `Stop` | hand-written | Entities: equality by `id`, and `freezed` cannot extend `Entity`. `Stop` also refuses its own input — a generated public constructor would let a caller skip `place`. |
| `GeoPoint`, `StopSequence`, `TravelWindow`, `TrafficProfile`, `ServiceTime`, `StopId`, `RoutePlanId` | hand-written | Every one of them refuses some of its own inputs, and a generated public constructor would let a caller skip the check. |

## What it may depend on

`core_kernel`, `core_ports`, `identity_api`, `shipments_api`. Third-party: `freezed_annotation`, `meta`.

Both foreign packages are here for **one identifier each** — `ActorId` and `ShipmentId`. A route is driven by an actor and a stop is usually about a parcel, and inventing local spellings for either would put the reconciliation in whichever adapter noticed first. Nothing else of theirs appears in this package's surface, and section 2.1 says why.

## What must never live here

- **An implementation of a port declared here.** Rule S8.
- **A DTO, or `json_annotation`.** Rules I4 and G2 — the wire shape of a route belongs to `routing_infrastructure`.
- **A foreign feature's *model*.** `AddressPoint`, `ShipmentSummary`, `Session`. Identifiers cross; concepts another feature owns do not.
- **A `GeoFix`, a permission state, or anything else from `platform/*`.** Not reachable, and that is the point.
- **The Flutter SDK.** Rule I2.

## Code generation

`build.yaml` enables `freezed`, narrowed to `lib/src/**.dart`.
