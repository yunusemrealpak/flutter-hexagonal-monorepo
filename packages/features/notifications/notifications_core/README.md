# notifications_core

The notifications use cases and the adapters that answer them: an inbox on device storage, and an alert channel over the push provider.

## This is the package the `feature_core` row exists for

`feature_application` may not depend on `platform/*` — that row forbids it outright, so in a full split `PushAlertChannel` would have to live in an `_infrastructure` package. `feature_core` may. The result is a `lib/src` where a use case and a device adapter are neighbours:

| Application half | Infrastructure half |
|---|---|
| `ReadInbox`, `MarkAlertRead`, `RecordArrivingAlert` | `KeyValueInboxStore`, `InboxEntryDto` |
| `OpenAlerts`, `CloseAlerts`, `NotificationsCoordinator` | `PushAlertChannel` |
| imports `notifications_api`, `core_ports` | imports `notifications_api`, `core_ports`, `platform/push_messaging` |

**Neither half imports the other**, and nothing but this README and the import blocks says so. That is the trade a reduced split makes, and it is why the day this feature needs a second channel — an in-app banner, an SMS fallback — the split is a `git mv`.

## `PushAlertChannel` is the whole port-versus-technology-contract argument in one file

`AlertChannel` asks whether a person can be reached. `PushMessagingClient` asks for a registration token. The adapter is the translation, and it is three translations rather than one:

- a **topic** becomes "alerts for this person" (`actor.<id>`);
- a `PushMessage` becomes an `ArrivingAlert` — the provider's envelope dropped, the product's vocabulary applied, the payload kept whole;
- a `PushFailure` becomes a `NotificationsFailure`, so a screen can tell "ask again" from "send them to the system settings" without knowing what Firebase calls either.

`openFor` asks for the token **before** subscribing, and the order matters: subscribing a device that was never granted permission succeeds at the provider and delivers nothing — no alerts and no failure to report.

## Two rules about identifiers, and they are not the same rule

**A sender that named the alert keeps its name.** Push delivery is at-least-once, so the same message arrives twice on a flaky connection; reusing the provider's identifier is what lets `InboxStore.put` recognise the second copy and drop it. The *stored* entry wins, because the arriving copy knows nothing about a read mark somebody may already have set.

**A sender that named nothing gets an identifier from `IdGenerator`.** Two copies of that alert are genuinely indistinguishable, and there is no honest way to deduplicate what the sender did not label. Minting a hash of the payload would look like a fix and would collapse two real assignments that happened to carry the same fields.

## The instant is receipt, not dispatch

`RecordArrivingAlert` stamps `Clock.now()`. Push can be delivered long after it was sent — a phone that was off, a network that was down — and an inbox sorted by send time would put an alert nobody has seen below one read this morning.

## The relay logs and stays alive

An alert arrives from the network, not from a person, so there is nobody to return a failure to. `NotificationsCoordinator._receive` logs and keeps the subscription: one that died on the first storage failure would leave a courier receiving nothing for the rest of the shift, silently.

The unread count is a **re-read**, not an increment. Two devices share an inbox, so a counter kept in memory would drift the first time the other one marked something read, and nothing would say when it had.

## What it may depend on

`core_kernel`, `core_ports`, `notifications_api`, `identity_api`, `push_messaging`, `flutter`

That list is section 2 of [`docs/DEPENDENCY_RULES.md`](../../../../docs/DEPENDENCY_RULES.md), one row. The `flutter` SDK entry is declared even though it arrives through `push_messaging`, because `melos run test` picks a test runner by looking for it — a package that needs `flutter test` and does not say so is handed to `dart test` and fails at import time.

## What must never live here

- **An import between the two halves.** See the table above.
- **`identity_api` in an adapter.** Both driven ports take a `String`. The `ActorId` stops at the coordinator.
- **`DateTime.now()` or `Random()`.** Rules A1 and A2 — and this package would notice, because both of its interesting rules are about time and identity.
- **A rendered notification string.** An entry carries a key and arguments; the sentence is the app's localisation.

## Code generation

None. `InboxEntryDto` is six fields and a hand-written codec. `json_serializable` is permitted on this row and would earn its place if the stored shape grew; today it would add a builder, a dev dependency and a generated file to review in every diff.
