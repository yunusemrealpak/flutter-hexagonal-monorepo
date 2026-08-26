# sync_presentation

The sync UI: a queue badge, and the screen a depot opens when it says something needs a person.

## What this screen cannot show

It renders a routing key, a reason and an attempt count. **Never the payload.**

That is not a layout choice. This package depends on `sync_api`, which cannot decode a payload — showing *"the delivery for shipment SHP-9"* would mean reaching into `delivery_api`, and at that moment `sync` would have learned a feature's name. Scenario 3 stops being true at the UI layer first, or not at all.

It turns out to be the honest shape anyway. The person resolving a stuck queue needs to know **what stopped and why**; turning a routing key into a link to the feature that owns it is the composing app's job, because the app is the only thing that depends on both.

## Five states, five sentences

`SyncStatusBadge.describe` is exhaustive over `SyncStatus`, and every case produces a different sentence:

| State | What the courier reads |
|---|---|
| `idle` | Everything is sent |
| `draining` | Sending 3 |
| `waitingForNetwork` | 3 waiting for signal |
| `waitingToRetry` | 3 will be retried |
| `blocked` | 1 need you |

This is why `SyncStatus` is a union rather than a count plus a boolean. *"You are in a basement"* and *"the server said no, we are trying again shortly"* send somebody to different places, and a badge that collapsed them into "not synced" is what makes a courier restart an app that is working correctly.

The wording lives here rather than on `SyncStatus`, because this is where the locale is known. A status carrying a formatted English string would be untranslatable a phase later. `describe` is static and public so a test can assert the sentence without pumping a widget tree.

## Two pieces of state, on purpose

`ReviewQueueController` exposes `state` (the list) and `status` (the badge) separately.

They answer different questions and change at different times: the badge follows the queue continuously, the list is read when somebody opens the screen. Folding the status into the state union would make every status change redraw a list that has not changed — and there is a test asserting it does not.

## Retrying re-reads instead of removing the row

Two people can be looking at the same review queue. A list that removed a row optimistically would disagree with the store the moment the other person resolved something.

## What it may depend on

`core_kernel`, `core_navigation`, `sync_api`, and the Flutter SDK.

Not `sync_application`, not `sync_infrastructure`. What actually answers `SyncFacade` is whichever app composed this: the real coordinator in `app_courier`, a fake in `app_harness`.

`design_system` is missing because it arrives in phase 7. The widgets here carry no colours, no typography and no spacing scale for the same reason — inventing them now would mean deleting them then.

## What must never live here

- **A use case or an adapter.** This package renders a state and calls a port.
- **A decoded payload.** Not reachable, and that is the point.
- **A formatted string in a state object.** `ReviewFailed` carries a `SyncFailure`; the sentence is chosen at the widget.

## Code generation

None. There is no `build.yaml` and no `build_runner` dependency, because nothing here is generated — four small sealed state cases are cheaper hand-written than a builder that has to run in every package that has one. CLAUDE.md §7.6 calls that the cheapest configuration rather than a missing one.
