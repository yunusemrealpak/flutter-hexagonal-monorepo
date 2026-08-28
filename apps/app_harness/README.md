# app_harness

The composition root that stands every feature up on fakes. It is not a product shell — it exists so that the wiring itself has a place to be tested.

## What it may depend on

Anything. `app` is the one row in section 2 of [`docs/DEPENDENCY_RULES.md`](../../docs/DEPENDENCY_RULES.md) with no prohibitions.

That is not a licence, it is the definition of a composition root: this is the only kind of package allowed to know both halves of a hexagon at once, which is exactly why nothing else is. `lib/src/di/harness_identity.dart` is the only file in the workspace where `IdentityCoordinator` and a `CredentialGateway` implementation are both in scope.

The `_testing` packages are `dependencies` rather than `dev_dependencies` here. This app's *product* behaviour is to run on fakes, so they ship in its `lib/` and not only in its tests.

## Why the modules are hand-written and the container is generated

Rule I6 forbids an annotation-based DI marker inside a package, so every adapter in the workspace is a plain class with a constructor. `injectable` cannot scan them.

What it scans instead is `lib/src/di/`, where an `@module` per concern lists what this app composes. That constraint turns out to be the feature: **the registration list is the composition, written down in one place**, rather than scattered across seventy packages as metadata nobody can read end to end.

128 registrations across eight modules. `injectable_generator` turns them into `injection.config.dart`, which is committed like every other generated file (§4.3).

## `HarnessWatchers` is the app answering a question the packages asked

`ShipmentFailureWatcher.start()` and `ShipmentOutcomeWatcher.start()` **return** their subscription rather than keeping it, and their doc comments say why: *"whoever started the watcher is the one that can stop it"*. Calling `start()` from a DI module and discarding the result throws that away, and the failure mode is the one those comments name — sign out, sign back in, and every incident is opened twice.

So `HarnessWatchers` holds all three subscriptions and can cancel them. It contains no product logic at all; it is three subscriptions and a `dispose`. That is what composition-root code looks like when the packages have done their job.

## The catalogue is `KeyEchoCatalogue`, and this app runs no `gen-l10n`

The only app in the workspace with no `.arb` file, deliberately. A harness whose job is to prove every feature can be stood up wants to see *which* key each screen asked for; a screen full of finished English would hide a label wired to the wrong key behind a sentence that reads fine.

`test/harness_app_test.dart` asserts exactly that: the sign-in screen draws `identity.signIn.title`.

## What the tests are for

| Test | What it catches |
|---|---|
| `container_test.dart` | a registration that asks for something nobody provides |
| `router_test.dart` | a screen added to a feature and never mounted; a guard that lets the wrong person in |
| `catalogue_test.dart` | a key manifest that names a key no catalogue can answer |
| `harness_app_test.dart` | a screen the container can build and a widget tree cannot hold |

**`container_test.dart` is phase 7's acceptance criterion**, and it is worth being clear about why "the container works" is not a tautology. `injectable` builds its graph at code-generation time and hands back a container that constructs *lazily* — so a registration whose dependency nobody provides compiles, generates, and throws the first time a screen is opened. Across 128 registrations that is a runtime error found by whoever navigated there. Resolving every facade forces the whole graph in milliseconds instead.

Three of its assertions are about the *shape* of the graph rather than its completeness, and those are the scenarios:

- `PaymentStatusReader` and `PaymentsFacade` resolve to the **same object** — scenario 1's proof that shipments reads payments through one contract and payments reads nothing of shipments.
- `SessionReader`, `PermissionChecker` and `IdentityFacade` are one object — a screen whose permissions came from a different instance than its session would offer actions to somebody not signed in.
- `HttpTransport` and `FakeHttpTransport` are one object — otherwise a test queues a response and a different adapter consumes it.

## `harnessUnmountedRoutes` is a decision, not a gap

The router reports every route with no screen behind it, and the test asserts that set **equals** a declared one rather than being empty. A screen somebody forgot to mount fails; a gap somebody decided on is written down.

Two routes are in it — `payments.refund` and `incidents.report` — because both need a form this workspace has not written. Phase 7's acceptance is that the wiring holds, not that every screen exists, and a placeholder mounted here would make the test stop being able to tell the two cases apart.

Two other routes *are* mounted, to a screen they share: `/stops/scan` is the manifest with a scanner deep-link, and `/board/assign` is the board reached through a wider permission. Mounting them to the same builder is how an app says "this is a mode, not a second screen".

## What must never live here

- **A business rule.** If a decision would be the same in `app_courier`, it belongs in a use case. This app should be able to be deleted without the product losing behaviour.
- **A widget that draws something.** `HarnessApp` installs a palette, a catalogue and a router. Everything a person sees comes from a presentation package.
- **`GetIt.instance`.** The container here is `GetIt.asNewInstance()`, because a global one is a container two tests share — and the first test's queued HTTP responses then fail the second one in a way that looks like an adapter bug.

## Code generation

`injectable_generator`, over `lib/src/di/` only. §4.1 puts it in `apps/*` and nowhere else; the `generate_for` glob is the DI directory rather than `lib/**`, because scanning the router and the shell for annotations that are not there is work every build pays for.
