# payments_api

The payments contract: money, what is owed on a parcel, the key that stops a retry becoming a second charge, and the ports that carry all three.

## `IdempotencyKey` is the identifier

`PaymentAttempt extends Entity<IdempotencyKey>`. Two attempts with the same key are the same attempt — that is what `Entity` equality already means — so a double charge is not a bug to guard against but a state the type system cannot express. Giving the attempt an identity of its own *beside* the key would have made "two attempts, one key" and "one attempt, two keys" both constructible, and one of those is somebody's money.

The key is opaque, not derived. Deriving it from the shipment and the amount would look clever and would collide the day a customer legitimately pays twice for the same parcel. `SettlementId` *is* derived, and the difference is instructive: a courier has exactly one settlement per day, so two devices computing it independently have to agree.

## Money is minor units in an `int`

0.1 + 0.2 is not 0.3 in binary floating point, and a settlement that adds four hundred cash collections in doubles is off by an amount somebody has to explain. Arithmetic across currencies returns `CurrencyMismatch` rather than a plausible number.

## What it may depend on

`core_kernel`, `identity_api`, `shipments_api`, `freezed_annotation`, `meta`

That list is section 2 of [`docs/DEPENDENCY_RULES.md`](../../../../docs/DEPENDENCY_RULES.md), one row. The two foreign `_api` packages are there for two identifiers, `ActorId` and `ShipmentId`. Section 2.1 is the rule — an identifier crosses, a model does not — so payments never learns what is in a parcel or where it is going.

The edge to `shipments_api` is one half of scenario 1. `shipments_application` will name `payments_api`; the graph stays acyclic because contract packages depend on no implementation.

## `PaymentStatusReader` is the other half of scenario 1

One question, one answer, like `SessionReader` beside `IdentityFacade`. Handing `shipments` the whole `PaymentsFacade` would also hand it the ability to take money; handing it a `PaymentAttempt` would let it reason about the idempotency key, the courier and the method — things it is not asking about.

## `collect` is idempotent about money, not about rows

Once money has moved under a key, sending the attempt again produces no second movement and the same answer. Until it has moved, the same key may be sent again to carry the intention forward — an office that recorded an expected cash amount, a courier who then took it.

Both halves are cases a courier meets. A retry in a tunnel must not charge twice; a collection the operation created before the visit must still be closable when the visit happens. A gateway that refused the second in the name of the first would leave every pre-recorded collection open for ever.

## What must never live here

- **An implementation of any port declared here.**
- **A DTO, or `json_annotation`.** Rules I4 and G2.
- **`flutter`.** Rule I2.
- **A `duplicateCollection` failure.** A second request carrying the same key is not an error; it is the same intention arriving twice, and the correct answer is the first one's result.
- **A card number.** `PaymentMethod.card` carries `last4`, which is what a customer recognises on a receipt and all a payments feature has any business holding.

## Code generation

`freezed` only, narrowed to `lib/src/**.dart` — rule G4. It produces the sealed unions (`PaymentsFailure`, `PaymentMethod`, `PaymentOutcome`, `PaymentStatus`). `PaymentAttempt`, `Settlement` and `Money` are hand-written: two of them are entities whose identifier goes through a constructor `freezed` cannot call, and all three carry rules rather than shapes.
