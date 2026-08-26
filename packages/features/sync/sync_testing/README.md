# sync_testing

Fakes, a builder and the contract kits for sync — consumed by other packages' tests, and by two of the three composition roots.

## A queue whose whole test suite never names a feature

Every test in and around this package queues a `TestSyncCommand`: a routing key and a body, belonging to no feature at all.

That is not a shortcut. `sync_testing` may not depend on `delivery_application`, so reaching for a real `CompleteDeliveryCommand` is not available even if somebody wanted it — and nobody should, because a fake that broke whenever delivery's use cases were refactored is a fake nobody would trust. **The fact that a queue's entire suite works without a real command is scenario 3 restated as a test-suite property.**

## Two of these fakes are product adapters

Scenario 5's table binds them:

| Port | `app_courier` | `app_dispatcher` | `app_harness` |
|---|---|---|---|
| `OutboxStore` | `DriftOutboxStore` | `InMemoryOutboxStore` | `InMemoryOutboxStore` |
| `CommandTransportPort` | `HttpCommandTransport` | `HttpCommandTransport` | `FakeCommandTransport` |

`app_dispatcher` runs the in-memory store on purpose: the operator is at a desk with a connection, and durability across a crash buys nothing there while a database file costs something. That is why the store lives here rather than being written twice — and it is why the contract kit matters more for this port than for most.

## The facade fake the writing features share

`FakeSyncFacade` is what `delivery_application` and `payments_application` queue through in their own tests. It lives here for the reason a fake always belongs beside its contract: two hand-written stubs in two features would drift apart the first time `SyncFacade` grew a method.

It lives under the same three constraints as the real queue. It records a routing key and a string and **never decodes a payload** — a test that wants to know *what* was queued asserts on the command object it handed in, through `queued`. It does not drain on enqueue, because a use case that queued and then waited for the network would be an offline-first product that is not. And it can refuse, which is the case worth writing a test for: a courier's proof that could not be queued exists only in memory, and a use case reporting success anyway would be lying about it.

## The contract kits

`runOutboxStoreContract` and `runCommandTransportContract`. One suite each, run against every implementation:

- here, against `InMemoryOutboxStore` and `FakeCommandTransport`;
- in `sync_infrastructure`, against `DriftOutboxStore` and `HttpCommandTransport`.

Two assertions in them are load-bearing:

**`put` is an upsert.** A feature that crashed between generating an identifier and writing the row retries with the same identifier. Two rows here is two payments taken at the same door.

**The same envelope sent twice is one piece of work.** An acknowledgement lost on the way back is indistinguishable from one that never happened, so a retry is guaranteed — and it has to be free.

What is deliberately *not* in a kit: anything only one implementation can arrange. There is no way to provoke a timeout or a 409 through `CommandTransportPort`, so those belong in each implementation's own tests. A kit with a back door stops being runnable against the other implementation, which is the whole reason to have one.

## The builder walks the entity

`OutboxEntryBuilder` reaches a state by calling `OutboxEntry`'s own methods. A builder that assigned `attempts` and `nextAttemptAt` independently could produce three attempts with nothing scheduled — a shape no drain creates. A test asserting against a fixture like that is asserting about a situation that never happens, and it passes for exactly as long as nobody notices.

Every instant is a parameter with a fixed default; nothing here calls `DateTime.now()` (rule A1), so a suite that builds a hundred entries builds the same hundred tomorrow.

## Why `test` is a runtime dependency

Because a contract kit *is* tests: `outbox_store_contract.dart` calls `group` and `test` from `lib/`. Leaving `test` in `dev_dependencies` would make that a `dev_dependency_in_lib` violation, and rightly so.

`core_testing` keeps `test` in dev dependencies because it ships only fakes, which are plain classes with no matchers in them.

## What it may depend on

`core_kernel`, `core_ports`, `core_testing`, `sync_api`, and `test` at runtime.

No foreign `_api` — the row in section 2 allows one, and this package has no use for it.

## What must never live here

- **Any implementation package.** Rule row `feature_testing`. A fake that depended on `sync_application` would break every time those use cases were refactored, which is the whole reason a contract package is separate from the code that satisfies it.
- **A real feature's `SyncCommand`.** Not reachable, and not wanted.
