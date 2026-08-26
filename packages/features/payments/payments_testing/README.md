# payments_testing

Fakes, fixtures and the contract kits for payments.

## The kit that matters

`runPaymentsGatewayContract`, and the three assertions at the top of it are the specification's "idempotency (critical)".

A courier taps *collect*, the request times out, the phone retries. The far side has to recognise the second copy as the same intention and answer with the first one's result. The kit's retry carries a **different instant**, so an implementation that recorded again is visible in the answer rather than invisible in a store nobody inspects.

It also asserts the half people forget: *two* intentions are two movements. A gateway that deduplicated on the shipment rather than the key would pass the first three tests and then refuse a customer who legitimately pays twice for one parcel, after a return.

What is deliberately **not** in the kit is anything only one implementation can arrange — a network timeout, a 409 from a real acquirer. Those belong in each adapter's own tests. A kit with a back door stops being runnable against the other implementation, which is the whole reason to have one.

## `FakePaymentStatusReader` is scenario 1's evidence

It is what `shipments_application` uses to test the other half of scenario 1: a question, an answer, and no knowledge of how payments arrives at it. Its size is the demonstration — a shipments test that had to build a `PaymentAttempt`, a cash drawer and a settlement in order to ask "is anything owed" would mean `PaymentStatusReader` was too wide a port.

## Two of these fakes are product adapters

| Port | `app_courier` | `app_dispatcher` | `app_harness` |
|---|---|---|---|
| `PaymentsGateway` | `RestPaymentsGateway` | `RestPaymentsGateway` | `FakePaymentsGateway` |
| `SettlementStore` | `DriftSettlementStore` | `InMemorySettlementStore` | `InMemorySettlementStore` |

`app_dispatcher` runs the in-memory store on purpose: the operator is at a desk with a connection, and durability across a crash buys nothing there.

## What it may depend on

`core_kernel`, `core_ports`, `core_testing`, `payments_api`, `identity_api`, `shipments_api`, and `test` at runtime.

`test` is a runtime dependency because a contract kit *is* tests: it calls `group` and `test` from `lib/`. Leaving it in `dev_dependencies` would be a `dev_dependency_in_lib` violation, and rightly so.

## What must never live here

- **Any implementation package.** A fake that depended on `payments_application` would break every time those use cases were refactored.
- **`DateTime.now()`.** Rule A1. `FakePaymentsGateway` stamps refunds from an instant it was given; a real adapter reads the one the server reported.
- **An assertion about how a real gateway does its work.** The kit asserts what a caller may rely on.

## Code generation

None. There is no `build.yaml` and no `build_runner` dependency — the cheapest configuration, not a missing one.
