# messaging_presentation

The messaging UI: the thread a courier reads and writes in, queued messages and all.

## A queued message stays where it was written

The list carries sent and unsent messages together, in the order they were typed, because the store *is* the queue. A screen that moved unsent messages to a separate tray would be showing a courier something the domain does not model, and they would have to look in two places to reconstruct what they said.

The status of each message is a chip beside the line. It was a semantics label until phase 7, which meant a screen reader could hear "written but not sent" and a person looking at the phone could not — the wrong way round, because the courier who needs it most is the one glancing at a screen in a van. The chip carries a word as well as a colour, so the distinction survives for somebody who cannot tell the two washes apart.

## The body is the one string here that is not a key

A person typed it. Everything else on screen is a localisation key, because that is the product speaking.

## The controller does not reload after sending

The facade announces the thread; the subscription this controller already holds does the reading. Doing both would read the thread twice for every message somebody types.

## The change stream is filtered in the controller

The facade announces *every* thread that moves, because one connection coming back drains several at once. Filtering here rather than there is what lets two thread screens exist at the same time without either redrawing for the other's traffic.

## What it may depend on

`core_kernel`, `core_navigation`, `identity_api`, `messaging_api`, `shipments_api`, `flutter`

That list is section 2 of [`docs/DEPENDENCY_RULES.md`](../../../../docs/DEPENDENCY_RULES.md), one row. `messaging_testing` is a dev dependency used only by `test/` — section 2.0 — and this package is the second consumer of it, which is why messaging has one at all.

## What must never live here

- **`messaging_core`.** Contracts only.
- **`core_ports`.** Not on this row; every instant on screen was stamped by a use case or by the server.
- **A separate tray for unsent messages.** See above.

## Code generation

None. One parameterised route does not yet pay for `go_router_builder`; the app that assembles the router will decide.
