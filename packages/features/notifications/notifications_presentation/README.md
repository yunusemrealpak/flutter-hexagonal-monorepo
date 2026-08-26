# notifications_presentation

The notifications UI: the inbox a courier opens, and the badge that tells them to.

## The badge is exported; the count is not

`UnreadBadge` is drawn on screens that have nothing else to do with notifications — a route list, a shipment detail. Exporting the widget rather than the number is what keeps those screens from having to hold a `NotificationsFacade` of their own, and it is the reason this package has two public widgets instead of one.

It renders nothing at zero. A badge reading "0" is a badge somebody has to look at in order to dismiss.

## The count and the list are separate

They answer different questions and change at different times: the badge follows `unreadCount()` continuously, and the list is read when somebody opens the inbox. Folding the count into `InboxState` would make every arriving alert redraw a list nobody is looking at.

## Marking read is a re-read, not a local edit

`InboxController.markRead` refreshes from the facade instead of updating the row it has. Two devices can be looking at one inbox, and an optimistic edit would disagree with the store the moment the other device cleared the alert.

## An empty inbox says so

`inbox.empty` is its own case rather than an empty `Column`. A screen with nothing on it reads as a screen that failed to load, and the failure case is right next to it.

## What it may depend on

`core_kernel`, `core_navigation`, `identity_api`, `notifications_api`, `flutter`

That list is section 2 of [`docs/DEPENDENCY_RULES.md`](../../../../docs/DEPENDENCY_RULES.md), one row. `notifications_core` is not on it, and neither is `platform/push_messaging` — the screen knows what an alert *is*, not how it arrived. `design_system` arrives in phase 7 and is what these plain widgets will be replaced with.

## What must never live here

- **`notifications_core` or `platform/push_messaging`.** A presentation package sees contracts, never implementations, and never a device.
- **`core_ports`.** Not on this row. Every instant on screen was stamped by a use case that had a `Clock`.
- **A sentence.** Labels are localisation keys; `InboxScreen.describe` is the single deliberate exception, so the exhaustive `switch` over `NotificationsFailure` lives where the compiler checks it.

## Code generation

None. One route with no parameters does not pay for `go_router_builder`.
