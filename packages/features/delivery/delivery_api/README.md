# delivery_api

The delivery contract: one visit to one address, what closes it, and what it takes to prove it happened.

The rule this package exists to place is `ProofPolicy`. How much evidence a hand-over needs depends on what the parcel is worth, and the specification asks for that rule to live in a policy object inside `_api`. `DeliveryAttempt.completeWith` consults it, so the rule holds for the courier's screen, for a dispatcher's correction and for a sync drain replaying a queued attempt alike.

## What it may depend on

`core_kernel`, `identity_api`, `shipments_api`, `freezed_annotation`, `meta`

That list is section 2 of [`docs/DEPENDENCY_RULES.md`](../../../../docs/DEPENDENCY_RULES.md), one row. A dependency outside it is a violation rather than an exception; `dart run melos run arch:check` will say which rule and how to fix it.

The two foreign `_api` packages are there for two types: `ActorId` and `ShipmentId`. Section 2.1 is the rule — an identifier crosses a feature boundary, a model does not — so there is no `Shipment`, no `ShipmentSummary` and no `AddressPoint` here. What delivery needs to know about a parcel is how much proof it is worth, and that is `DeliveryGrade`, delivery's own word.

## What must never live here

- **An implementation of any port declared here.** `ProofStorePort` has two answers and both live in `delivery_infrastructure`.
- **A DTO, or `json_annotation`.** Serialization is an infrastructure concern; rules I4 and G2 check it.
- **`flutter`.** This package is pure Dart, which is what keeps its tests fast.
- **A failure that is really an outcome.** A courier who found nobody home did their job: that is `NonDeliveryReason`, on the success side of the `Result`.
- **Coordinates.** `GeoFencePort` asks *am I there yet* and gets back a distance, which is why delivery needs no point type of its own and borrows nobody else's.

## Code generation

`freezed` only, narrowed to `lib/src/**.dart` — rule G4. It produces the sealed unions (`DeliveryFailure`, `NonDeliveryReason`, `AttemptOutcome`) and one data class (`GeoFenceVerdict`).

Everything else is hand-written, and the split follows the workspace's rule: `freezed` produces the data-carrying skeleton, and validation stays in factories that return a `Result`. `DeliveryAttempt` is hand-written because `Entity` takes its identifier through a constructor a generated subclass cannot call; `DeliveryCompleted` is hand-written for the same reason with `DomainEvent`.
