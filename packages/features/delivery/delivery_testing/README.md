# delivery_testing

Fakes, fixtures and the contract kit for delivery.

The kit that matters is `runProofStoreContract`. Three implementations of `ProofStorePort` run it: the encrypted local store and the remote one in `delivery_infrastructure`, and `FakeProofStore` here. One description of what a proof store must do, three answers held to it — so `app_courier` can keep a courier's signatures encrypted on the device while `app_dispatcher` keeps them on a server, and no use case changes.

## What it may depend on

`core_kernel`, `core_ports`, `core_testing`, `delivery_api`, `identity_api`, `shipments_api`, `test`

That list is section 2 of [`docs/DEPENDENCY_RULES.md`](../../../../docs/DEPENDENCY_RULES.md), one row. A dependency outside it is a violation rather than an exception; `dart run melos run arch:check` will say which rule and how to fix it.

The two foreign `_api` packages are there because a fixture attempt names a courier and a shipment — which is what `DeliveryAttempt` names. Section 2.1 holds here too: no fixture builds a `Shipment` or a `ShipmentSummary`, and none needs to.

`test` is a runtime dependency rather than a dev one, because a contract kit *is* tests: it calls `group` and `test` from `lib/`. Leaving it in `dev_dependencies` would be a `dev_dependency_in_lib` violation, and rightly so.

## What must never live here

- **`delivery_application` or `delivery_infrastructure`.** A fake that broke whenever those were refactored is a fake nobody trusts, which is the whole reason a contract package is separate from the code that satisfies it.
- **An assertion about how a real adapter does its work.** The kit asserts what a caller may rely on. A local reference is a row identifier and a remote one is whatever the server minted; pinning the format would fail the kit on the day it was supposed to earn its keep.
- **`DateTime.now()` or `Random()`.** Rules A1–A3. `FakeProofStore` mints references from a counter, which is also more readable in a failure message.

## Code generation

None. There is no `build.yaml` and no `build_runner` dependency — the cheapest configuration, not a missing one.
