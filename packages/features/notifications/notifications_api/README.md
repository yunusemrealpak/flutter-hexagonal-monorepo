# notifications_api

The notifications contract: what lands in a courier's inbox, when it counts as read, and the two ports that carry it.

## `AlertChannel` is the product's words for what `PushMessagingClient` says in Firebase's

The two interfaces look almost the same, and they are on opposite sides of the line [`docs/DEPENDENCY_RULES.md`](../../../../docs/DEPENDENCY_RULES.md) §2.2 draws:

| | `AlertChannel` (here) | `PushMessagingClient` (`platform/push_messaging`) |
|---|---|---|
| Asks | can this person be reached | give me a registration token |
| Delivers | `ArrivingAlert` | `PushMessage` |
| Fails with | `AlertsRefused`, `AlertsBlocked`, `AlertsUnreachable` | `PushPermissionDenied`, `PushPermissionBlocked`, `PushRegistrationFailed` |
| Knows about | actors and alerts | tokens and topics |

Nothing in the product asks for a push token. Deleting the port and letting the use cases hold `PushMessagingClient` directly would compile — a `feature_core` package may depend on `platform/*` — and it would put the choice of provider inside the feature's rules, where a test could not replace it and a second channel (SMS, an in-app banner) could not be added without touching them.

## An alert carries a key, not a sentence

`assignment` plus `{'shipment': 'SHP-42'}`, which an app's localisation renders. A `String title` here would put one language in the domain and make every stored alert untranslatable.

## The read mark is an instant

"Read" and "read at 14:02" are the same fact stored twice if both are kept, and only one of them answers a dispatcher asking when a courier saw a route change. Marking is idempotent and the **first** mark wins: two devices show the same inbox, and the second one to tap is reporting the same fact later.

## Two factories, because an arriving alert is unread by definition

`InboxEntry.arriving` takes no read mark; `InboxEntry.stored` requires one and refuses a mark that predates the arrival. One factory with a nullable `readAt` would let a caller build an alert that arrived already read — a state the product has no way to produce.

## `unrecognised` is not a parse failure

`NotificationKind.unrecognised` means the *outside world* sent something this version does not classify, which is normal traffic in a fleet that updates over weeks. `NotificationKind.parse` failing means a record the product wrote itself cannot be read, which is corruption. Collapsing them would turn every future server change into an error report.

## What it may depend on

`core_kernel`, `identity_api`

That list is section 2 of [`docs/DEPENDENCY_RULES.md`](../../../../docs/DEPENDENCY_RULES.md), one row. `identity_api` is there for `ActorId` on the driving port, and for nothing else.

## What must never live here

- **`platform/push_messaging`.** Not on this row, and the reason is the table above.
- **An implementation of either port.** Rule S8.
- **A DTO, or `json_annotation`.** Rules I4 and G2.
- **A rendered notification string.** See above.

## Code generation

None. One entity, one value object, one enum and two ports are less code than the `build.yaml` that would produce them.
