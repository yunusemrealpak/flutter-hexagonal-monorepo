# messaging_core

The messaging use cases, the thread store that doubles as the offline queue, and the transport that drains it.

## Messaging keeps its own queue instead of using `sync`'s outbox

`delivery` and `payments` enqueue a `SyncCommand`; this feature does not, and the difference is a judgement worth writing down rather than an oversight.

`sync` carries **opaque payloads a feature wants delivered once and then forgotten** — a completed delivery, a collection. A queued message is none of those things:

- it is *content a person sees*, in the thread, where they wrote it;
- it has to appear in the order it was written, which a generic outbox does not promise per thread;
- somebody may well delete it before it ever goes.

Putting it in `sync` would mean two lists to keep in step — the thread on screen and the payload in the outbox — and they would disagree the first time a send failed halfway.

**The test, for the next feature that has to choose:** if a person can see the queued thing, it belongs beside the thing they can see. If it is a write nobody looks at again, it belongs in `sync`.

## A refusal and a deferral are different, and every layer turns on it

| Layer | What it does with a deferral | What it does with a refusal |
|---|---|---|
| `HttpMessageTransport` | 5xx, offline, timeout → `DeliveryDeferred` | 4xx → `DeliveryRefused` |
| `DeliverMessage` | leaves it queued, silently | logs it, leaves it queued |
| `DrainQueue` | stops — nothing behind it will go either | steps over it — it never will |

`DeliverMessage` exists as a class of its own precisely so that this rule is written once. Two copies would drift, and the drift would show up as a message that sends on retry but not when it is written.

## `SendMessage` succeeds when the message is stored

Not when it is sent. A courier in a tunnel has written the message; reporting a failure would make them write it again and the operation would get it twice. The only thing that fails the use case is the *store* — a device that cannot write the message down has genuinely lost it, and that is the one case where "try again" is the right answer.

A refused message is kept, not dropped. Silently discarding something somebody typed is the one behaviour a messaging feature must not have.

## Read receipts mark what other people wrote

A receipt on your own message means nothing, and producing one would show a courier that the operation had read a message the operation has not seen. A queued message cannot be read at all, and asking is not an error — two devices resynchronising in the wrong order produce exactly that.

One receipt goes to the server, for the newest message. One request per line of a conversation would be one request per line of a conversation.

## What it may depend on

`core_kernel`, `core_ports`, `messaging_api`, `identity_api`, `shipments_api`, `http_dio`

That list is section 2 of [`docs/DEPENDENCY_RULES.md`](../../../../docs/DEPENDENCY_RULES.md), one row. `messaging_testing` is a dev dependency: the contract kit runs in `test/` and never in `lib/`.

## What must never live here

- **An import between the two halves.** `KeyValueMessageStore`, `HttpMessageTransport` and `MessageDto` import no use case; no use case imports them.
- **`sync_api`.** See the first section — and if that judgement is ever revisited, it is revisited here, in the open.
- **`DateTime.now()` or `Random()`.** Rules A1 and A3.
- **A second copy of the deferral/refusal rule.** It is in `DeliverMessage`.

## Code generation

None. `MessageDto` is seven fields and a hand-written codec.
