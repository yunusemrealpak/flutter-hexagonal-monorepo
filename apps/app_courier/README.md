# app_courier

The courier's phone: offline-first, device-bound, and the first column of the adapter table in §5.5 of the specification.

## What it may depend on

Anything — the `app` row in section 2 of [`docs/DEPENDENCY_RULES.md`](../../docs/DEPENDENCY_RULES.md) has no prohibitions. That is the definition of a composition root rather than a licence: this is the only kind of package allowed to see both halves of a hexagon, which is why nothing else is.

**Twelve features, not fourteen.** `shipments_presentation_dispatcher` and everything of `reporting` are absent, and their absence costs nothing: neither is a dependency, so neither is compiled in. An app is a set of *features* as much as a set of adapters, and that is the half of scenario 5 the table does not show.

## `CourierPlatform` is the composition root taking its own dependencies

Every adapter in `platform/*` takes a plugin's **platform interface** through its constructor rather than reaching for the plugin's singleton. That was decided in phase 2 so an adapter could be tested without a device; [`CourierPlatform`](lib/src/di/courier_platform.dart) is what it buys at the top of the tree.

`main.dart` builds one from the real plugin instances. [`test/support/test_platform.dart`](test/support/test_platform.dart) builds one from an in-memory SQLite file and six stubs — and gets *the same container*, with the same adapters, the same use cases and the same screens. Nothing between there and a courier's screen knows the difference.

The alternative — an adapter that called `FirebaseMessaging.instance` — would have made this app's container untestable, and would have made `push_messaging` untestable first.

## The adapter table, and why it is a test

| Port | Here | `app_dispatcher` | `app_harness` |
|---|---|---|---|
| `RouteOptimizerPort` | `LocalHeuristicOptimizer` | `RemoteSolverOptimizer` | `FakeRouteOptimizer` |
| `CredentialGateway` | `DeviceBoundCredentialGateway` | `SsoCredentialGateway` | `FakeCredentialGateway` |
| `OutboxStore` | `DriftOutboxStore` | `InMemoryOutboxStore` | `InMemoryOutboxStore` |
| `ProofStorePort` | `LocalEncryptedProofStore` | `RemoteProofStore` | `FakeProofStore` |
| `PaymentsGateway` | `RestPaymentsGateway` | `RestPaymentsGateway` | `FakePaymentsGateway` |

Each of those is asserted in [`test/container_test.dart`](test/container_test.dart), with the reason beside it. The reasons are the point: a courier in a tunnel still has to know where to go next; a stolen password is worth nothing without the handset; writes have to survive the app being killed in a lift; a signature captured in a basement is kept until the queue drains.

**The last row is the most instructive.** Two apps agree, and a table where every row differed would be describing a rule rather than a set of decisions.

The claim these bindings make is that the packages *below* them do not change — and the only way that claim breaks silently is a binding changing without anybody noticing which app they were in. Hence a test rather than a paragraph.

## The catalogue is the test `app_harness` cannot fail

The harness answers every key by definition — `KeyEchoCatalogue` returns the key — so its coverage test checks a *manifest*. This one checks a *translation*: 163 sentences in English and Turkish against the keys twelve presentation packages declare.

[`catalogue_test.dart`](test/catalogue_test.dart) checks both directions. A key with nothing behind it is a courier reading `settings.theme.dark` while choosing a palette. A sentence nobody asks for is a translation somebody is paying to maintain in every language the product ships — and it happens when a screen is rewritten and its `.arb` entry stays behind.

**It found a real gap on its first run.** `ShipmentsCourierStrings.all` did not list the seven status keys: the list lived only in the dispatcher package, which this app does not depend on. Both packages now declare the same seven, and each has a `switch` over `ShipmentStatus` keeping its copy honest. That duplication is the price of section 2's rule that a presentation package may not depend on another, and this is where the price came due.

## `courierUnmountedRoutes` is three different decisions

- `routing.courierRoute` is somebody *else's* route — a dispatcher's screen. `routing_presentation` declares both destinations and this app draws one. A feature is not all-or-nothing, and the guard would have refused this route anyway.
- `payments.refund` and `incidents.report` need a form this workspace has not written.
- `shipments.courier.scan` is **not** in the set: it is the manifest reached from a scanner deep-link and is mounted to the same builder. A mode is not a second screen.

## The four tabs are this app's answer, not a feature's

`courierTabs` names four tabs, each a word, a picture and the routes behind it. Twelve presentation packages declare where they can be reached; none of them knows it ended up behind a bar, and `routing_presentation` is mounted by `app_dispatcher` too, where there is no bar at all. That is §2.3's rule — a driving surface belongs to the audience — one level above where it was written: not *which* operations an audience performs, but which of them are one tap away.

**`core_navigation` did not have to change for it.** The one thing a feature must be able to say about a tab root is that it opens with no argument, and `RouteDefinition.path` already says it: `/stops` can be a tab and `/stops/:shipmentId/proof` cannot. `courier_shell_test.dart` reads `path` and asserts exactly that, so a branch concept in a core contract package would have been a field three apps carry to express what one of them can derive.

The split is the same one §2.4 draws for flows, one level down: `PeykNavigationBar` reports an index and knows no route, `courierTabs` names routes and draws nothing, and `CourierShell` — in this app — is the only place where an index becomes a destination.

Everything mounted is behind exactly one tab except `identity.signIn`, and the shell test asserts that partition exactly. A route added to a feature has to be given a home rather than quietly becoming unreachable.

## An ended session forgets where it was

The guard sends anybody without a session to `/sign-in?from=<where they were going>`, so that a parcel somebody followed a link to survives signing in. An *ended* session is refused at whatever screen its owner was on — so without a second decision, the next person to sign in on a shared handset would land on the previous courier's parcel.

Interception and ejection look identical to `redirectFor`: both are a session-requiring route with no session. They are told apart in `SessionRefresh`, the only place that sees the transition, and the app answers by clearing the location before the guard reads it. The shell test is what found this; it predates the shell.

## `PeykRouter` is duplicated in `app_harness`, deliberately

An app may depend on anything, so a shared router package would compile — and it would be the first `common` package in the workspace, which is the mistake §2.1 names. Two apps assembling route modules are two apps making the same decision, not one decision they share: the day `app_dispatcher` wants a shell route with a persistent sidebar, that file changes there and not here.

Ninety lines is what that costs. The alternative is a package three apps negotiate over — and this app is now the proof: it grew a `StatefulShellRoute` and the other two did not. A shared router would have had to grow a branch parameter that two of its three callers pass nothing to.

## `courier_runtime.dart` is where ambient state is allowed in

Rules A1–A3 forbid `DateTime.now()`, `Random()` and a UUID call in every package in the workspace; `apps/*` is the exception. That file is what makes the exception a boundary rather than a hole: five small classes, each one line of ambient state behind a port, and nothing else in this app touching any of it.

`UuidGenerator` is hand-rolled rather than taken from `package:uuid` for the same reason — `uuid` reaches for `Random.secure()` itself, so an app that used it would have a `RandomSource` port that nothing behind it obeys.

## What must never live here

- **A business rule.** If a decision would be the same in `app_dispatcher`, it belongs in a use case.
- **A widget that draws something.** `CourierApp` installs a palette, a catalogue and a router.
- **`GetIt.instance`.** A global container is a container two tests share, and the first test's SQLite file then fails the second in a way that looks like an adapter bug.

## Code generation

Two generators, and §4.1 puts both in `apps/*`:

- `injectable_generator` over `lib/src/di/` only — 110 registrations. `throwOnMissingDependencies` is on, so a module asking for something nobody provides fails the build rather than the first screen that opens.
- `flutter gen-l10n`, configured in [`l10n.yaml`](l10n.yaml), writing into `lib/src/l10n/`. Committed like every other generated file (§4.3), because one that exists only inside `.dart_tool` cannot be reviewed and cannot be seen by the affected-test selection derived from `git diff`.
