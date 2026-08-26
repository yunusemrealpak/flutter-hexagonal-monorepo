# messaging_testing

Fakes, fixtures and the contract kit that holds every message store to keeping a thread in order.

## Why this feature has a `_testing` package and the other six do not

Section 7 of [`CLAUDE.md`](../../../../CLAUDE.md) says to create one only when another package consumes its fakes. Here two do:

- `messaging_core` runs `runMessageStoreContract` against `KeyValueMessageStore`, while this package runs it against `InMemoryMessageStore`. One kit, two implementations, no drift.
- `messaging_presentation` drives `FakeMessagingFacade` in its widget tests.

`settings`, `notifications`, `incidents`, `vehicle_inventory`, `documents` and `reporting` keep their stand-ins in their own `test/` folders, because nothing outside those features consumes them. Creating a `_testing` package for each of them would be six more packages whose only purpose is to be imported once.

## `test` is a runtime dependency here

A contract kit *is* tests: it calls `group()` and `test()` from `lib/`. Leaving `package:test` in `dev_dependencies` would make that a `dev_dependency_in_lib` violation, and rightly so.

## Fakes, not mocks

`InMemoryMessageStore` really stores, really replaces by identifier and really orders. `FakeMessagingFacade` really keeps threads, and really leaves a message queued when it is told the device is offline. A test written against them exercises the caller's logic rather than a script of expected calls, which is why it keeps passing when the caller is refactored and starts failing when the caller is broken.

Both can be told to fail. Failure is part of a port's contract, so a fake that could not produce it would leave every caller's failure branch untested.

## The kit's assertions are ordered by what breaks first

Ordering before storage, because a store that sorts by insertion looks correct until two devices synchronise. `put` replacing rather than appending next, because that is the one an implementation gets wrong by writing an obvious `add`.

## What it may depend on

`core_kernel`, `core_ports`, `core_testing`, `messaging_api`, `identity_api`, `shipments_api`, `test`

That list is section 2 of [`docs/DEPENDENCY_RULES.md`](../../../../docs/DEPENDENCY_RULES.md), one row.

## What must never live here

- **`messaging_core`.** A fake that depended on the use cases would break whenever they were refactored, which is the whole reason a contract package is separate from the code that satisfies it.
- **A fixture that builds a `Shipment`.** Identifiers cross; models do not.
