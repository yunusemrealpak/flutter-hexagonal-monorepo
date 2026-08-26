# messaging_api

The messaging contract: a thread between a courier and the operation, what counts as read, and the two ports that carry it.

## Three instants, and each answers a different question

`writtenAt`, `sentAt`, `readAt`. A message written in a tunnel has the first and not the second. A thread sorted by `sentAt` would reorder itself when the signal came back and put a courier's question after the answer to it — so the order is the *writing* order, and the send instant is a fact about the message rather than its position.

A boolean `isSent` would collapse the first two into one fact and lose the only thing anybody asks afterwards, which is how long the message sat.

## The queue is the store, not a second list

A message is written locally and sent afterwards, so "queued" means *stored and not yet sent*. A separate outbox would be a second list to keep in step with the thread on screen, and the two would disagree the first time a send failed halfway.

That is also why `MessageStore` has `queued()` on it rather than a `MessageQueue` port beside it: one list, two questions.

## `ThreadId` is derived; `MessageId` is minted

Two devices have to agree on which conversation they are in without asking anybody, so a thread is `shipment:SHP-42` or `courier:courier-7`. The same device has to be able to name a message before any server has seen it, so a message identifier is minted locally — which is what makes a resend after a timeout recognisably the same message.

The same split as `SettlementId` and `IdempotencyKey` in payments, for the same reasons.

## `DeliveryDeferred` and `DeliveryRefused` are not the same failure

Try again, versus never. An adapter that collapsed them would produce either an outbox that gives up in a tunnel or one that retries a closed thread for ever, and both are noticed weeks later.

Neither is shown to a courier as an error: a message written with no signal is queued, not lost. The cases exist so that whatever drains the queue can tell the two apart.

## `MessageTransport` answers with an instant

The server's, not the device's. Two phones in different time zones with drifting clocks would each stamp their own, and one thread would sort differently on each of them.

## What it may depend on

`core_kernel`, `identity_api`, `shipments_api`

That list is section 2 of [`docs/DEPENDENCY_RULES.md`](../../../../docs/DEPENDENCY_RULES.md), one row. A thread may be *about* a parcel; it never carries one.

## What must never live here

- **An implementation of either port.** Rule S8.
- **A DTO, or `json_annotation`.** Rules I4 and G2.
- **A second queue.** See above.
- **A rendered timestamp.** The instants are `DateTime`s; turning one into "2 minutes ago" is the app's localisation.

## Code generation

None.
