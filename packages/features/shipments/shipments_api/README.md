# shipments_api

A parcel, where it is, and what may happen to it next. Entities, value objects, ports, the sealed failures they return, and the domain events shipments publishes about itself.

## The state machine

This is what the package exists to demonstrate.

```text
awaitingAssignment -> assignedToCourier -> loadedOnVehicle
  -> outForDelivery -> deliveredToConsignee | undeliverable
                     | returnedToDepot
```

It lives in `Shipment`, as one `switch` over `(from, to)` pairs — not in a use case, not in an adapter, not in a screen. A move that is not on the diagram returns `ShipmentFailure.invalidTransition`, and it does so no matter which driving adapter asked: a courier's scan screen, a dispatcher's table, a sync drain, a test. That is what makes the rule a property of the domain rather than a property of whoever remembered to check.

Three consequences worth noticing in the code:

- **`copyWith` has no `status` parameter.** A `copyWith(status: …)` would be a way around the entire machine that looked like ordinary code. Changing state is what the transition methods are for.
- **The courier check is a separate failure.** `NotTheAssignedCourier` is not `InvalidTransition`. The move is legal and the person asking is the problem; reporting it as a bad transition would tell a courier who scanned a colleague's parcel that the parcel is in the wrong state.
- **`at` is a parameter, never a call.** Rule A1. A state machine whose rules take the time as an argument is one whose tests never wait for anything.

`shipment_state_machine_test.dart` asserts the whole 6×7 matrix — every legal move succeeds, every other pair is refused — plus a check that the legal-pair list still names states that exist. A test that only walked the happy path would keep passing after somebody added an edge.

**One row a real operation would add.** A second attempt after `undeliverable`, which is `undeliverable -> outForDelivery`. It is left out because the specification's machine is what this package demonstrates. That adding it is *one entry in one table* is the argument for the table.

## Why it depends on `identity_api`

A shipment is assigned to an actor, and the only vocabulary for "an actor" is the one identity publishes. A `CourierId` of our own would make the two features disagree about who somebody is the first time a courier was also a dispatcher, and would put the reconciliation in whichever adapter noticed first.

The edge reaches `identity_api` and nothing else, which is the whole reason contract packages are separate from implementations: the graph stays acyclic even though identity's own screens will eventually read shipments.

## Where the line around code generation is drawn

Same calibration as `identity_api`, and this package is where it gets its hardest cases.

| Shape | How | Why |
|---|---|---|
| `ShipmentStatus`, `ShipmentFailure` | `freezed` | Closed unions of small values. A state *is* its contents, so structural equality is correct. This is the union the specification asks to see generated — and what `freezed` does *not* express is which state may follow which, because that is a rule rather than a shape. |
| `StatusTransition`, `ShipmentSummary` | `freezed` | Records and read models. No identity, nothing to validate, nothing secret. |
| `Shipment` | hand-written | An entity: equality by `id`, so a shipment that moved from assigned to loaded is still the same shipment. `freezed` also cannot extend `Entity` — the generated subclass would have to call `super(id: …)` from a const `._()` with no `id` in scope. |
| `ShipmentId`, `Barcode` | hand-written | Private constructor plus a validating factory returning `Result`. `Barcode` carries a modulo-10 check digit, and a generated public constructor would let a caller skip it. |
| `AddressPoint`, `Consignee` | hand-written | Multi-field values that have something to check. A latitude of 91 is not a place. |
| `ShipmentDelivered`, `ShipmentFailed`, `ShipmentReturned` | hand-written | Same constraint as `Shipment`: `DomainEvent` takes `occurredAt` through its constructor, and a generated subclass has nothing in scope to pass. |

The rule underneath the table: **generate the shapes, hand-write the rules and anything that has to refuse its own input.**

## What it may depend on

`core_kernel`, `core_ports`, `identity_api`. Third-party: `freezed_annotation` and `meta`, both annotation-only.

## What must never live here

- **An implementation of a port declared here.** Rule S8. `shipments_application` implements `ShipmentsFacade`; `shipments_infrastructure` answers the driven ports; the fakes and the contract kit live in `shipments_testing`.
- **A DTO, or `json_annotation`.** Rules I4 and G2. The wire shape of a shipment belongs to `shipments_infrastructure`, together with the mapper that translates it.
- **The Flutter SDK.** Rule I2.
- **A localisation key, or anything a screen would display verbatim.** `ShipmentStatus.label` is a stable name for failure messages and the transition table, not a caption. What a courier reads is decided by a presentation package.

## Code generation

`build.yaml` enables `freezed`, narrowed to `lib/src/**.dart`. `json_serializable` is absent rather than disabled: it is not a dev dependency here, so naming it would fail the build instead of tightening it.
