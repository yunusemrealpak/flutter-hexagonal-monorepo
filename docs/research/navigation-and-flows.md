# Screens that never call each other: navigation, and the three flows

**Status:** decided on 2026-08-30. Implemented across the commits titled
`feat(arch_check): a presentation package may not navigate…`,
`feat(presentation): outcomes, not destinations…` and
`feat(apps): the courier's day, assembled where the features meet`.

**Where the rule now lives:** [`DEPENDENCY_RULES.md` §2.4, "Who is allowed to
navigate"](../DEPENDENCY_RULES.md), enforced by `arch_check` rules `I8` and
`A6`. The narrative belongs in `docs/ARCHITECTURE.md` under scenario 7, which
is the scenario this work extends.

---

## 1. What was observed

Seventy-five packages, thirteen routes in `app_courier`, ten in
`app_dispatcher`, and:

```
navigation calls in every _presentation package in the workspace: 0
```

No `context.go`, no `goNamed`, no `Navigator.of`. Every screen is an island
reachable only by typing its URL. The architecture is assembled and the product
does not move.

That is not an accident of laziness. It is the constitution working: a
presentation package may depend on `core_navigation`, `design_system`, its own
`_api` and other features' `_api` packages — and on nothing that could navigate.
`go_router` appears in the three apps' pubspecs and nowhere else. So the moment
anyone wants a flow, they meet the question this note answers.

## 2. The question

A courier finishes recording proof at a door. Where do they go next?

Three answers were possible, and each is defended somewhere in the literature.

| | How a screen continues | Cost |
|---|---|---|
| **(a)** | `context.goNamed('payments.collect', …)` inside the screen | `go_router` enters fourteen packages; a feature names another feature's route as a string the compiler cannot check |
| **(b)** | an `AppNavigator` port in `core_navigation`, app supplies the adapter | the port has to name every destination, so `core_navigation` learns all thirteen features |
| **(c)** | the screen reports an **outcome**; the app decides the destination | one more constructor parameter per screen, and a flow that lives in the app |

## 3. What the literature said

- **Android's Compose-era multi-module guidance and Now in Android**: *"You
  shouldn't pass the navController directly into any composable and instead pass
  navigation callbacks as parameters."* Feature modules take
  `onTopicClick: (String) -> Unit`; the parent decides what that means. This is
  (c), from the largest reference monorepo Google maintains.
- **Android's XML-era multi-module guidance** disagrees in form and agrees in
  substance: it passes the `NavController` down, and then forbids the thing
  that matters — a feature module may not name another module's destination.
  Its answer for crossing the boundary is a **deep link**, i.e. a URL. That is
  (a), restricted to the one case where (a) is unavoidable.
- **The Flutter forum's multi-package thread** reaches (b): an abstract
  `AppRouter` in a base package, features depend on the interface, the app
  implements it. Worth taking seriously, and §4 says why it does not survive
  this repository's §1.1.
- **Very Good Ventures' routing guide and `docs.flutter.dev/app-architecture`**
  both call `context.go` from inside a screen, and both are written for a
  single-package app. `flutter.dev` permits *"simple routing logic"* in a view.
  Neither addresses a package that must not know which app it is running in.
- **The coordinator / flow-controller literature** supplies the shape of the
  app half and one warning worth writing down: a coordinator is pointless if
  the screen tells it which screen to push. The callback has to carry *what
  happened*, never *where to go*.

## 4. The decision: (c), outcomes reported upward

**(a) does not compile here in any honest form.** A `_presentation` package may
not import another feature's `_presentation` package, and route names are
declared in presentation packages. So a shipments screen cannot reach the
symbol `delivery.proof`; it can only spell it as a string. The dependency
would be real, invisible to `dart analyze`, invisible to `arch_check`, and a
rename in `delivery` would break `shipments` at runtime.

**(b) is the `shared` package with a different name.** An `AppNavigator`
interface has to declare a method per destination, so `core_navigation` — the
package every presentation package depends on — would name all thirteen
features. §2.1 forbids exactly this shape, and the reason applies unchanged:
adding a feature would edit a core contract package.

**(c) already exists in this repository, under a different heading.**
`ProofCaptureScreen` takes `onCaptureSignature` and `onCapturePhoto` because
§1.1 forbids a presentation package from depending on `platform/*`. The app
supplies the capability; the screen offers the button when it is supplied and
draws nothing when it is not. A flow step is the same shape: the screen offers
the outcome, and the app decides what it means. Nothing new is introduced —
an existing technique is applied to a second kind of thing the screen may not
know.

**The flow is audience-specific, which is why the app owns it.** A courier
goes manifest → route → door → money. A dispatcher looking at the same delivery
screens goes nowhere near a door. This is §2.3's rule one level up: a driving
port is drawn per audience, and so is a flow. The only place that knows which
audience is running is the app that mounted the features.

### 4.1 What (c) does not answer, and where (a) survives

A callback cannot be invoked by a notification tap, a scanned barcode or a
pasted URL. **Entry is the router's job and stays a URL**; continuation is the
app's job and becomes an outcome. The split is exact:

| | Mechanism | Owner | Already existed |
|---|---|---|---|
| Entry — deep link, push payload, typed URL | `RouteDefinition.path` | feature declares, app assembles | yes |
| Admission — session, permission | `PeykRouter.redirectFor` | app | yes |
| Continuation — "this screen is finished" | outcome callback | app | **no** |
| Session change — sign-in, sign-out, expiry | `refreshListenable` | app | **no** |

### 4.2 The rule that keeps it from becoming two conventions

An unwritten rule that everyone happens to follow is a rule that breaks the
first time somebody is in a hurry. Two `arch_check` rules make the choice
impossible rather than discouraged:

- **`I8`** — `package:go_router/` may be imported only by an `app`.
- **`A6`** — `context.go`, `context.goNamed`, `context.push`,
  `context.pushNamed`, `context.pushReplacement`, `context.replace`,
  `Navigator.of`, `Navigator.push`, `Navigator.pop` and their relatives are
  forbidden callees outside `apps/*`.

`A6` reuses the machinery `A1`–`A5` already use for `DateTime.now()`: an AST
callee match, not a grep. Today both rules pass with zero violations, which is
the point — they are written while the workspace is clean, so the first
violation is somebody's mistake rather than a migration.

## 5. The three flows

### S1 — The session, from launch to sign-out

**What was missing.** `IdentityFacade.signOut()` had no call site anywhere in
the workspace. `sessionChanges()` was implemented and nobody subscribed. The
router had no `refreshListenable`, so `redirectFor` ran only on navigation: a
session that ended while somebody was looking at a screen left them on it.

**What was built.**

- `SettingsScreen` takes `onSignOut`, offered only when supplied — the same
  shape as `onCapturePhoto`. `settings_presentation` still does not depend on
  `identity_api`.
- The apps wire it to `IdentityFacade.signOut()`.
- `PeykRouter` takes the session stream and refreshes on it, so the guard is
  evaluated when the session changes rather than when somebody navigates.
- `redirectFor` learned `from`: a guarded destination reached without a session
  redirects to `/sign-in?from=<encoded>`, and a signed-in actor on the sign-in
  screen is sent to `from` when it is there and home when it is not.

**Why `from` is a query parameter and not a field.** The router is rebuilt on
every refresh and a field would have to survive that; the URL already does, and
it is also what a cold start from a notification produces.

### S2 — The courier's day

```
shipments.courier.manifest ──onStopSelected──▶ delivery.proof/:shipmentId
delivery.proof ──onSettled──▶ payments.collect/:shipmentId
payments.collect ──onFinished──▶ shipments.courier.manifest
```

Three features, three callbacks, and **not one import between them**. Each
callback carries a value from its own `_api` — a `ShipmentId`, a
`DeliveryAttempt`, a `PaymentAttempt` — and the app translates.

**Delivery always continues to payments, and payments decides there is nothing
to do.** `CollectionState` already had `NothingOwed` as a state of its own,
distinct from an amount of zero. Routing every settled delivery through
collection is what makes the prepaid case visible instead of hypothetical, and
it keeps delivery from having to know what a parcel costs — which it may not,
because `delivery` does not depend on `payments`.

**A callback fires on a state transition, never during `build`.** Each screen
adds a listener in `initState`, checks for its terminal state, and calls the
callback once behind a latch. Rebuilding is not an event; a screen that fired
its outcome from `build` would fire it again on every notification.

### S3 — Offline writes, and who drains them

**What was missing.** `SyncFacade.drain()`'s own documentation named the caller:
*"whatever decides that now is a good moment — a connectivity change, a
foreground transition, a timer in the composition root."* Nothing did. Writes
went into the outbox and stayed there until somebody opened `sync.review` and
pressed retry.

**What was built.** A `SyncOrchestrator` in each app that owns a device queue:
it subscribes to `NetworkStatus.changes()`, drains when the condition becomes
online, drains once at start-up, and drains on a foreground transition.

**Why it is in the app and not in `sync_application`.** A use case that
subscribed to connectivity would be a use case that runs forever, and
`DrainOutbox` is a use case that runs once. The decision "now is a good moment"
is not sync's — sync knows what is due, not what else the device is doing. This
is the composition root owning a policy that belongs to no feature, which is
the same reason the container lives there.

## 6. Acceptance criteria, checked

1. `arch_check` carries `I8` and `A6`, and both pass across 75 packages — **done**,
   with fixtures in `broken_imports` and `broken_apis` proving each one fires
   and that a doc comment naming the call is not a violation.
2. No `_presentation` package gains a dependency; §1.1's table is unchanged —
   **done**. Every callback carries a type from the screen's own `_api`.
3. `IdentityFacade.signOut` has a call site, and ending a session moves the
   person to sign-in without a navigation happening first — **done**, through
   `SettingsScreen.onSignOut` and the router's `SessionRefresh`.
4. A guarded URL reached without a session returns to that URL after sign-in —
   **done**, with the two refusals tested: a `from` pointing at sign-in, and a
   `from` carrying a scheme.
5. The three courier screens carry outcome callbacks, each tested for firing
   once on the transition and not on a rebuild — **done**, and each is also
   tested with no callback supplied, which is `app_dispatcher`.
6. A connectivity change from offline to online drains the outbox, asserted
   against a fake `NetworkStatus` rather than a device — **done**, along with
   the repeat-condition, concurrent-drain and refused-drain cases.
7. `dart analyze`, `arch_check`, `graph:check` and the full suite stay clean —
   **done**.

### What building it changed about the design

**The flow forks on the outcome, and the first version did not.** `onSettled`
fires for a visit that ended *without* a hand-over too, and the first
`afterProof` sent every settled attempt to collection — a courier who took the
parcel away again would have been asked to collect for it. `AttemptOutcome` is
sealed, so the fix is a switch the compiler checks.

**Two terminal states, two different mechanisms.** Proof announces on the
transition; collection offers a button. `NothingOwed` arrives the instant the
collection screen loads, and announcing it automatically would take a prepaid
parcel off the screen before anybody read the word. Mid-task continues,
end-of-task asks.

**`GoRouterRefreshStream` no longer exists.** go_router dropped it after
version 17, so `SessionRefresh` is fifteen lines in each app. It throws the
session value away deliberately: the guard reads `SessionReader.current` when
it runs, and a second copy of that fact would eventually disagree.

## 7. What was ruled out and why

- **A `flows` or `navigation` package holding the flow definitions.** It would
  have to name every feature's routes, which is (b) with a longer path. Two
  apps assembling similar flows are two apps making the same decision — the
  same reasoning that keeps `PeykRouter` duplicated rather than shared.
- **A `StatefulShellRoute` with a bottom navigation bar, in this change.** It is
  wanted and it is a separate decision: tabs are per-audience surfaces, they
  need `RouteDefinition` to gain a branch concept, and a branch concept in
  `core_navigation` is a change to a core contract. Doing it in the same change
  as the flows would have hidden which of the two forced the contract to move.
- **Navigating from a controller instead of a screen.** The controller is the
  half of presentation that is pure and unit-tested; giving it a destination
  would put a route name in the one place that is currently free of them.

## 8. One thing this note did not notice until afterwards

`core_navigation` already contains a `Navigation` port — `goTo`, `replaceWith`,
`back` — whose doc comment says *"Presentation packages depend on this rather
than on a router library… The app supplies the adapter."* That is candidate
(b), written in phase 1 and never used: no package outside `core_navigation`
and `core_testing` mentions the type.

So the repository currently ships an unused port whose documentation teaches
the design §4 rejects. It is recorded in `CLAUDE.md` §10 as the first thing to
settle, and the recommendation there is to delete it: dead code that teaches
the wrong lesson is worse than no code. `RouteLocation` stays either way — it
is a tested value object, and a shell route may want it.
