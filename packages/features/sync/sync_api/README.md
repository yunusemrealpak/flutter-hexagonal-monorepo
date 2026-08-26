# sync_api

A durable queue that carries every feature's writes and can name none of them.

## The inverted arrow

This is the package scenario 3 of the specification is about, and the whole of it is visible in the pubspec: **`sync_api` depends on no feature.** Not `delivery`, not `payments`, not `shipments` — and it never will.

The intuition says a synchronisation feature knows what it synchronises. It does not. What it knows is `SyncCommand`, which is two strings:

```dart
abstract interface class SyncCommand {
  String get type;     // a routing key: 'delivery.completeAttempt'
  String get payload;  // already serialised, never decoded here
}
```

A feature implements that in its own `_application` package, hands it to `SyncFacade.enqueue`, and gets an `OutboxEntry` back. The composition root — in an app, which is allowed to depend on everything — is the only place that maps a `type` to the transport handler that answers it.

The consequence to notice: nothing in this package can decode a payload, so nothing in it can grow a `switch` over feature names. That is not restraint, it is arithmetic — `sync_application` has no dependency that would let it write `payments` down.

## Why the entry carries a `ConflictPolicy`

Because the answer to "the server has moved on, now what?" is a business question, and `sync` is structurally incapable of answering it.

Whether a courier's offline proof-of-delivery outranks whatever the office typed while the phone was in a dead zone is a fact about the operation. `delivery` knows it; `sync` sees an opaque payload. So the policy is chosen by the feature at the moment it enqueues, travels on the entry, and is consulted by the drain:

| Policy | On conflict | Chosen by |
|---|---|---|
| `lastWriteWins` | resend against the server's new cursor | work where the newest fact is the true one |
| `serverWins` | drop the entry | work already superseded by definition |
| `manualReview` | block for a person | work where guessing costs money or evidence |

## Transient and permanent are not the same failure

`SyncFailure.isTransient` is the single question the retry schedule asks, and it is on the failure type rather than in the use case for the usual reason: two callers would eventually disagree.

A queue that cannot tell "the tunnel ate the request" from "the server says this command is nonsense" does one of two harmful things — it retries the nonsense until the head of the queue is permanently stuck, or it discards the tunnel case and loses a delivery that actually happened. Both are the same bug.

A conflict is deliberately reported as **not** transient. Whether trying again helps is the entry's `ConflictPolicy`'s answer, not the failure's; calling it transient would let the schedule retry a write the server has already decided against.

## Why the backoff is a pure function

`RetrySchedule.delayAfter(attempts, jitter:)` takes the randomness as a `double` instead of reaching for `Random()`.

That is rule A2, and here it buys something concrete: a test states *"the jitter was 0.5"* and asserts an exact `Duration`, instead of running the schedule a thousand times and asserting on a distribution. The jitter itself comes from the `RandomSource` port, drawn once by the use case that records the attempt — and the resulting instant is **stored** on the entry as `nextAttemptAt`, not recomputed on read. A due-time recomputed from a jittered schedule would answer differently on every call, and an entry would flicker in and out of being due.

Full jitter — a draw from `[0, backoff]` rather than `backoff` plus a wobble — is what spreads a depot's worth of devices that all lost wifi at the same second.

## A blocked entry is skipped, not deleted

`OutboxEntry.blocked(reason)` takes work out of the drain and leaves it in the store. Two failure modes are being avoided at once:

- **Deleting it** destroys the record of a delivery or a payment that the operation still has to reconcile. A queue may not decide that on its own.
- **Leaving it at the head** stops everything behind it. One rejected entry and the whole shift's work never lands.

`SyncStatus.blocked` therefore reports `pending` and `needingReview` separately: the rest keeps draining while a person deals with the two that cannot.

## Where the line around code generation is drawn

Same calibration as `shipments_api`.

| Shape | How | Why |
|---|---|---|
| `SyncFailure`, `ConflictPolicy`, `SyncStatus` | `freezed` | Closed unions of small values. A state *is* its contents, so structural equality is correct. |
| `SyncEnvelope` | `freezed` | One attempt, no identity of its own. Two envelopes with the same contents are the same attempt. |
| `OutboxEntry` | hand-written | An entity: equality by `id`, and the id is also the server's idempotency handle. `freezed` also cannot extend `Entity`. |
| `RetrySchedule` | hand-written | It validates its inputs and it carries a rule. |
| `OutboxEntryId`, `SyncCursor` | hand-written | Value objects. `OutboxEntryId` has a validating factory returning `Result`; `SyncCursor` deliberately has none, because any token the server issued is valid. |

The rule underneath: **generate the shapes, hand-write the rules and anything that has to refuse its own input.**

## What it may depend on

`core_kernel`, `core_ports`. Third-party: `freezed_annotation`, annotation-only.

No feature. That is the package's defining property, not an omission.

## What must never live here

- **An implementation of a port declared here.** Rule S8. `sync_application` implements `SyncFacade`; `sync_infrastructure` answers the driven ports; the fakes and contract kits live in `sync_testing`.
- **A `SyncCommand` implementation.** Not a rule violation — `SyncCommand` is declared here, so a class implementing it here would be one — but more importantly a design one: a command belongs to the feature that wrote it.
- **A DTO, or `json_annotation`.** Rules I4 and G2. `SyncEnvelope` is the domain's description of an attempt; the wire shape belongs to `sync_infrastructure`.
- **The Flutter SDK.** Rule I2.

## Code generation

`build.yaml` enables `freezed`, narrowed to `lib/src/**.dart`. `json_serializable` is absent rather than disabled: it is not a dev dependency here, so naming it would fail the build instead of tightening it.
