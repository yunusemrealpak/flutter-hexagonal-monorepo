# Turning alerts on: the screen the port was written for

**Status:** design, approved 2026-09-01. Closes backlog item 8 of
`CLAUDE.md` §10 and one row of
[`docs/research/integration-audit.md`](../../research/integration-audit.md).

**The problem.** `NotificationsFacade.openAlertsFor` and `closeAlertsFor` have
no callers anywhere in the workspace. Nothing subscribes a courier to their
alert topic on sign-in and nothing unsubscribes on sign-out.
`PushAlertChannel.openFor` — which is also the only code that requests the
notification permission — never runs. Push is inert end to end, and the
deep-link entry merged in PR #19 can only ever be reached by a notification the
device was never registered to receive.

**Why it was never a wiring fix.** The port says so itself: *"Called from a
screen that has already explained why, never on first launch."* Subscribing
automatically on sign-in would prompt for the notification permission with no
explanation, spend the single iOS prompt, and contradict the contract in
writing. The app's established pattern for every other permission is
request-on-use — and alerts have no moment of use, which is exactly why they
need a screen the workspace does not have.

---

## 1. The three decisions

Each was a fork with a defensible other side. They are recorded here so that
the next session argues with the reasoning rather than rediscovering the fork.

### 1.1 The surface is a section on the settings screen

The alternatives were a dedicated screen in `notifications_presentation` and a
priming step in the sign-in flow.

Apple's Human Interface Guidelines and Android's `POST_NOTIFICATIONS` guidance
agree on the mechanism — explain the value, then request — and on iOS the
system prompt is spent once and does not come back. So the question was never
*whether* to prime; it was where the explanation lives.

A **sign-in priming step** has the highest opt-in rate and the worst failure
mode: somebody who declines has no way back in from inside the app, ever. It is
a surface that can only be used once, for a decision the person is allowed to
change.

A **dedicated screen** puts ownership in the right feature but costs a route, a
tab placement, a set of catalogue keys, and a mount decision in three apps —
for a screen holding one switch.

A **settings section** is durable, reversible, needs no new route, and carries
its own explanation above the switch. The priming *is* the section. Settings is
also where a person already goes to change their mind about how the product
behaves, which is what this is.

### 1.2 `notifications` owns whether alerts are open

`FirebaseMessaging` exposes no way to read which topics a device is subscribed
to. So "this device opened alerts for this actor" cannot be recovered from the
provider; it has to be stored.

Storing it in `settings_api`'s `UserPreferences` was rejected. That type's own
doc comment says preferences have no identity of their own and the actor is the
key the record is stored under — it is a fact about a *person*. Whether alerts
reach a device is a fact about a *device*: a courier with two handsets wants
alerts on the one they are carrying. Putting it in `UserPreferences` would make
both phones answer the same way, and would leave `settings` owning a preference
it has no adapter to act on.

So `notifications` gets a driven port and an adapter, and
`settings_presentation` draws what the facade answers. §1.1 of the constitution
gives a presentation package other features' `_api` packages, which is exactly
the edge this uses — the same edge it already uses for `identity_api`.

### 1.3 `PermissionRequester` gains `openSettings()`

`AlertsBlocked` exists as a case separate from `AlertsRefused` for a stated
reason: *"one offers a button, the other has to send somebody to the system
settings. Collapsing them is how an app ends up with a button that does
nothing."* Nothing in the workspace can open the system settings, so the
distinction currently buys nothing.

`core_ports`' bar for entry is *more than one feature needs it, none owns it*.
Three packages produce a blocked-permission case — `media_capture`,
`location_service` and `push_messaging` — and no feature owns the notion of a
settings screen. It meets the bar the same way `status` and `request` do.

---

## 2. Where the state comes from

Two facts combine into one answer.

| Fact | Source | Why there |
|---|---|---|
| The operating system's notification permission | `PermissionRequester.status(DevicePermission.notifications)` | reads without prompting, already in `core_ports` |
| Whether this device opened alerts for this actor | new `AlertRegistry` over `KeyValueStore` | the provider will not say, so it must be remembered |

The combination, and the screen treatment each produces:

| Permission | Registry | `AlertState` | The screen shows |
|---|---|---|---|
| `granted` | open | `AlertsOpen` | switch, on |
| `granted` | closed | `AlertsClosed` | switch, off |
| `notDetermined` | either | `AlertsClosed` | switch, off |
| `denied` | either | `AlertsClosed` | switch, off |
| `permanentlyDenied` | either | `AlertsUnavailable` | a sentence and a button to the system settings |
| `restricted` | either | `AlertsUnavailable` | the same |

The permission is read first and `AlertsUnavailable` short-circuits: a device
that may not be asked again has no use for the registry, so that row cannot
fail on a store read. Every other row reads the registry, and a store failure
there answers `Failed(AlertStateUnavailable)` rather than guessing at a value.

**Reading the permission first is what makes the stored fact honest.** A courier
who turns notifications off in the phone's own settings leaves the registry
saying "open". Reading the registry alone would draw a switch that is on while
nothing arrives — the exact failure `DeskAlertChannel`'s doc comment warns
about, in a different disguise. Reconciling on every read is what keeps the
stored fact from becoming a lie.

---

## 3. What changes, package by package

### 3.1 `notifications_api`

A driven port, in the product's words and speaking in `String` like every other
driven port this feature has:

```dart
abstract interface class AlertRegistry {
  Future<Result<bool, NotificationsFailure>> isOpenFor(String actorId);
  Future<Result<void, NotificationsFailure>> rememberOpen(String actorId);
  Future<Result<void, NotificationsFailure>> forget(String actorId);
}
```

A sealed state, three cases:

```dart
sealed class AlertState { const AlertState(); }

/// Alerts reach this device.
final class AlertsOpen extends AlertState { const AlertsOpen(); }

/// Alerts do not reach this device, and the app may still ask.
final class AlertsClosed extends AlertState { const AlertsClosed(); }

/// Alerts do not reach this device and the app may not ask again.
/// Only the system settings screen can change it.
final class AlertsUnavailable extends AlertState { const AlertsUnavailable(); }
```

Three cases rather than five. The two things a screen has to decide are whether
to draw a switch and which way it points; a state carrying `notDetermined` and
`denied` separately would offer a distinction no caller can act on.

One method on the driving port:

```dart
Future<Result<AlertState, NotificationsFailure>> alertStateFor(ActorId actor);
```

And one failure case:

```dart
/// Whether this device is open to alerts could not be read.
final class AlertStateUnavailable extends NotificationsFailure { ... }
```

Its own case rather than `InboxUnavailable` because the two sit behind
different stores and lead to different screens: an unreadable inbox draws a
retry over a list, and an unreadable alert state leaves a switch with nothing
honest to draw. `NotificationsFailure`'s class doc counts the alert cases and
the inbox cases; that count is updated in the same commit.

### 3.2 `notifications_core`

- **`KeyValueAlertRegistry`** — beside `KeyValueInboxStore`, same shape, its own
  key namespace (`notifications.alerts.`). One key per actor holding a flag.
- **`OpenAlerts({channel, registry})`** — opens the channel and, on success,
  remembers. Its own doc comment already predicted this: *"Keeping that true
  when there is nothing to compose is what makes it obvious where the first
  rule goes."* This is the first rule.
- **`CloseAlerts({channel, registry})`** — closes the channel and forgets **only
  on success**. If `unsubscribeFrom` fails the device is still receiving, and
  forgetting would record a state the device does not have.
- **`ReadAlertState({registry, permissions})`** — the one place the two facts
  meet. It takes `PermissionRequester` from `core_ports`, which a use case is
  allowed to hold, and which makes the whole matrix testable with
  `FakePermissionRequester`.
- **`NotificationsCoordinator`** — gains `alertStateFor`, delegating.

`PushAlertChannel` does not change. `AlertChannel` does not change, so
`DeskAlertChannel` in `app_dispatcher` does not change either.

### 3.3 `core_ports` and `platform/device_permissions`

```dart
/// Opens the system settings page for this application.
///
/// Answers whether the page was opened, not whether anything was changed
/// there — the app is backgrounded at that point and finds out by reading
/// [status] again when it returns.
Future<bool> openSettings();
```

Not a `Result`. A settings page that would not open is not a failure a caller
can route around; there is no second way to send somebody there. This matches
the port's existing stance that nothing on it returns `Result`.

`DevicePermissionRequester` answers it with `permission_handler`'s
`openAppSettings()`. `FakePermissionRequester` records the calls, the same way
it records `requested`.

### 3.4 `design_system`

A new `PeykSwitchRow`: a label, an optional description line, a value, and an
`onChanged` that is null while a write is in flight.

`PeykOptionRow` cannot be reused. It declares
`Semantics(inMutuallyExclusiveGroup: true, selected: …)` — it is one choice
among several, and a screen reader announces it that way. A toggle is
`Semantics(toggled: …)`, and the two are different promises to somebody who
cannot see the screen.

### 3.5 `settings_presentation`

A new `AlertsController` and a private `_AlertsSection` on the existing screen.
The package gains a `notifications_api` dependency — the row §1.1 already
grants it, and the second foreign `_api` it holds after `identity_api`.

```dart
SettingsScreen({
  required SettingsController controller,
  AlertsController? alerts,   // null: the section is not drawn
  VoidCallback? onSignOut,
})
```

The same shape as `onSignOut`, for the same reason: the app decides whether
this surface exists. `app_dispatcher` passes nothing — `DeskAlertChannel`
declines every open, so a switch there would be a control that cannot work.

New keys on `SettingsStrings`: `alerts.section`, `alerts.explanation`,
`alerts.toggle`, `alerts.blocked`, `alerts.openSettings`, and three failure
keys. They are declared here rather than borrowed from
`NotificationsStrings` because a presentation package may not depend on another
presentation package — and because a key belongs to the screen that asks for
it, which is the reasoning already written down for `settings.signOut`.

**A deliberate consequence:** the keys join `SettingsStrings.all`, so
`app_dispatcher` has to answer strings for a section it never draws. The
catalogue coverage test is a floor on what an app can answer, not a claim about
what it shows.

### 3.6 `apps`

- `app_courier`'s `settings.home` builder passes an `AlertsController` built
  from `container<NotificationsFacade>()`, the `permissions` already in scope,
  and `actor()`.
- All three apps' `onSignOut` closes alerts before ending the session. The order
  is forced: closing needs the actor, and signing out is what takes it away.
- `.arb` entries and catalogue rows in `app_courier` and `app_dispatcher`.
  `app_harness` answers through `KeyEchoCatalogue` and needs none.

---

## 4. Testing

| Where | What it proves |
|---|---|
| `notifications_core` | the full permission × registry matrix of §2, one case per row |
| `notifications_core` | a failed `unsubscribeFrom` leaves the registry open |
| `notifications_core` | opening records only after the channel succeeded |
| `settings_presentation` | turning the switch on calls `openAlertsFor` |
| `settings_presentation` | `AlertsUnavailable` draws a button, not a switch, and the button calls `openSettings` |
| `settings_presentation` | a null `alerts` draws no section |
| `app_courier` | sign-out calls `closeAlertsFor` *before* `signOut` |
| `core_testing` | `FakePermissionRequester` records `openSettings` |

Every test that pins down a fix is run once with the fix removed. Phase 8's
lesson stands: a test that passes without the change is not a test.

---

## 5. Out of scope, deliberately

- **The sign-in priming step.** The settings section was chosen over it; doing
  both doubles the surface area for a decision that is already reversible.
- **Wiring `openSettings` into the camera and location blocked paths.** The port
  arrives here; those two call sites are their own change, and the audit lists
  them as such.
- **`tokenChanges()` still has no subscriber.** Routing is by topic, so a
  rotated token is largely the provider's problem to migrate. The audit already
  says so.
- **An in-app presentation for an alert that merely arrives.** Unchanged from
  the push-entry note.
