# sync_infrastructure

The sync adapters: what answers its ports, the DTOs that cross the wire, and the mappers between them.

## Three boundaries, and what stops at each

| Adapter | What stops here |
|---|---|
| `DriftOutboxStore` | SQL, and exceptions |
| `HttpCommandTransport` | status codes |
| `HttpClockSkew` | "what time does the server think it is" |

### `DriftOutboxStore`

The store `app_courier` binds. An offline-first app has to survive the operating system reclaiming it mid-shift, and a queue in memory does not.

`app_dispatcher` binds `InMemoryOutboxStore` from `sync_testing` instead — an operator is at a desk with a connection, so a database file costs something and buys nothing. That is why both run `runOutboxStoreContract`: "what the fake does" and "what the real one does" being the same sentence is the difference between two applications behaving alike.

It takes **two DAOs rather than a `PeykDatabase`**, so what it can reach is visible in its constructor: the outbox table, and one namespace of the key-value table. The cursor lives in that key-value namespace rather than in a table of its own — it is a single opaque string per device, which is exactly what that table is for, and a table with one row in it is a migration nobody needed.

Everything it catches collapses to `OutboxUnavailable`. That is deliberate: the caller behaves identically for a locked database, a full disk and a corrupt file — it stops the drain, because a store that cannot be trusted to remember must not be written into. `storage_drift`'s own `storeFailureFrom` makes finer distinctions for `KeyValueStore` because *that* port's callers act on them. Inventing cases nobody branches on is how a sealed union stops being worth matching over.

### `HttpCommandTransport`

The only place in the whole feature where a status code exists.

| What came back | What the queue is told | What `DrainOutbox` does |
|---|---|---|
| offline, DNS, refused | `SyncOffline` | stop, count no attempt |
| timeout, 5xx | `SyncTransportFailed` | back off and retry |
| 409, or a 2xx with `conflict: true` | `SyncConflict` | ask the entry's `ConflictPolicy` |
| any other 4xx | `SyncRejected` | block it for a person |

Move any row of that table upwards and the retry policy stops compiling the day this API becomes gRPC.

Two rows are worth dwelling on. **The 5xx/4xx split** is what stops a bad deploy turning a fleet's queues into a review backlog, and what stops one malformed command being retried forever. **A 2xx that says `conflict`** has to be noticed: reading it as an acceptance would drop the entry and lose the write, which is the most expensive mistake available in this package.

The identifier goes out in an `Idempotency-Key` header as well as in the body, because that is where a server's idempotency middleware looks — usually before anything has parsed the body.

### `HttpClockSkew`

`server - device`, so positive means the server is ahead, and the device's reading comes from the `Clock` port. Rule A1 is not decorative here: a port whose entire job is to compare two clocks must not read one of them ambiently.

The measurement is deliberately naive — no round-trip halving, the way NTP does it. The product needs skew accurate to about a second, enough to stop a device whose clock is an hour out from winning every last-write-wins contest, and a hundred milliseconds of round trip does not affect that. Writing the halving here would suggest a precision this feature does not have.

The answer is cached for fifteen minutes. Asking on every drain would put a request in front of every batch of work, which is a strange thing to do on a device whose defining problem is that requests are expensive.

## Why the mappers are hand-written

A generated mapper would still have to be told what a missing field, an unrecognised policy name and a non-UTC instant mean — which is the entire content of those two files. Generating them would only move the decisions into a configuration nobody reads.

Two of those decisions:

**A routing key splits into `feature` and `operation`.** The table has two columns because a person reading a stuck queue wants to filter by feature; the domain has one key because that is what a composition root maps to a handler. A key with no `.` is filed under `unknown` rather than refused — a row that cannot be stored is work that has been *lost*, which is worse than a row filed under the wrong heading.

**An unrecognised `conflict_policy` reads as `lastWriteWins`.** The union is closed and the column is open, so a downgrade or a hand-edited database can produce a value nothing here knows. `lastWriteWins` is the only case that neither discards the device's work nor demands a person's attention, so it is the safe direction.

**`toUtc()` on the way out** is the one line that is easy to omit and hard to notice missing. Without it, a device set to Istanbul time sends local instants that the server reads as UTC, and every offline write appears to have happened three hours early.

## Why `FakeHttpTransport` is not used for the contract kit

`FakeHttpTransport` is a *queue* of scripted answers — the right shape for testing a mapping, and the wrong shape for testing idempotency. The assertion the transport contract exists for, *the same envelope twice is one piece of work*, needs a stand-in that actually remembers. The smallest honest one is nine lines and lives in the test file.

It is used everywhere else in the suite, which is what it is for.

## What it may depend on

`core_kernel`, `core_ports`, `http_dio`, `storage_drift`, `sync_api`, `json_annotation`.

Not `sync_application`. Section 2 forbids the edge, and this is where the constitution earns it: nothing here can call a use case, so nothing here can quietly grow one.

## What must never live here

- **A use case.** Deciding whether to retry, block or drop is `DrainOutbox`'s job. This package answers "what did the server say".
- **A foreign feature's `_api`.** An adapter that needed one has taken on a use case's job. `sync` cannot name a feature anyway, which makes the rule unbreakable here rather than merely enforced.
- **A DTO in `sync_api`.** Rules I4 and G2 — that is what this package's `sync_envelope_dto.dart` is for.

## Code generation

`build.yaml` enables `json_serializable`, narrowed to `lib/src/**.dart`. `freezed` is absent because it is not a dev dependency here. `drift_dev` is absent for a more interesting reason: **this package declares no tables.** The schema lives in `platform/storage_drift`, which owns one database per application rather than one per feature, so there is nothing here for a drift builder to generate.
