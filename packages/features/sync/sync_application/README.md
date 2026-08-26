# sync_application

The sync use cases: pure Dart, blind to every adapter that answers its ports — and to every feature whose work it carries.

## `DrainOutbox` is a list of decisions, not a loop

This is the only place in the workspace that holds a retry policy. Read it as four rules:

### Offline stops the drain without counting an attempt

The request never left, so it was not an attempt. Count it and a device in a tunnel burns its whole budget in a single pass — eight failures in eight milliseconds — and a shift's work ends up in the manual-review queue because of a lift.

### A store failure stops the drain and is reported

Everything else in this feature is *"not yet"*. A store that cannot be read is a queue that cannot be trusted to remember, and continuing to write into one is how work disappears quietly. This is the only outcome `drain()` reports as a failure.

### A permanent failure blocks one entry; the rest keep draining

Retrying a 422 produces the same 422 until a person looks. Leaving it at the head of the queue stops everything behind it — the failure mode a naive queue gets wrong.

### A conflict is the entry's `ConflictPolicy`'s decision

Not this class's. The feature chose the policy when it queued the work, because whether the device's version outranks the server's is a business question that `sync` — which sees an opaque payload — cannot answer.

The server's new cursor is saved in all three branches, because the device has now heard it. Pretending otherwise would make the next envelope conflict against a position it already knows is stale.

| Policy | What the drain does |
|---|---|
| `lastWriteWins` | records an attempt; the next envelope goes out against the new cursor |
| `serverWins` | drops the entry — the work is finished, not failed |
| `manualReview` | blocks it, with the server's own explanation attached |

## Why the backoff is testable

`RetrySchedule` takes the jitter as a `double`. The drain draws it once from the `RandomSource` port and writes the resulting instant onto the entry, so `drain_outbox_test.dart` can assert:

```dart
expect(waits, [
  const Duration(milliseconds: 500),   // 1s backoff, 0.5 jitter
  const Duration(seconds: 1),          // 2s
  const Duration(seconds: 2),          // 4s
]);
```

Three exponential backoffs asserted exactly, in a test that takes microseconds. Rule A2 is what makes that possible; without it the same assertion is a sampled distribution, or a `sleep`.

## `ReadSyncStatus` is its own use case

Three callers need the same answer — the drain when it finishes, the coordinator after a queue changes, and a screen when it opens — and each would otherwise compute a slightly different one.

Its check order is a product decision: **blocked work is reported even when the device is offline**, because "two of these need you" outranks "you are in a basement". The second resolves itself and the first does not.

## What is not here

**No feature's name.** This package's pubspec lists `core_kernel`, `core_ports` and `sync_api`. There is no dependency that would let a use case here decode a payload or branch on which feature queued it. That is scenario 3 as a compile-time property rather than a convention.

**No `Flutter`.** Rule I2 — this is where roughly 80% of the suite's speed comes from.

**No adapter.** `DriftOutboxStore` and `HttpCommandTransport` live in `sync_infrastructure`, which this package may not see and does not need to.

## What it may depend on

`core_kernel`, `core_ports`, `sync_api`. Dev: `core_testing`, `sync_testing`, `test`.

## What must never live here

- **A rule that belongs on the entity.** Whether an entry is due, how a blocked one behaves, what an envelope carries — that is `OutboxEntry`'s, in `sync_api`. A use case orchestrates; an entity decides.
- **A decision `SyncCoordinator` makes on its own.** It delegates to five use cases and owns a stream. If it grows a rule, a use case is missing.
- **`DateTime.now()`, `Random()`, `print()`.** Rules A1, A2, A4 — all three would be easy here and all three are ports.
