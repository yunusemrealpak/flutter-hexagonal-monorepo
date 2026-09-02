# background_tasks

The scheduling contract an app asks for work while it is not running, its WorkManager/BGTaskScheduler adapter, and the fake that keeps tests off the operating system's queue.

## What it is for

| Type | Role |
|---|---|
| `BackgroundScheduler` | the contract: schedule a name, or a `Result` saying why not |
| `WorkManagerScheduler` | the only file in the workspace that imports workmanager |
| `FakeBackgroundScheduler` | records what was asked for, so no test waits for an operating system |
| `TaskConstraints`, `sealed SchedulingFailure` | the vocabulary they share |

## Why the contract lives here and not in `core_ports`

Same reason as `HttpTransport` in `http_dio` and `LocationSource` in `location_service`: nothing in the product asks for "a periodic task". `sync` asks for its outbox to be drained, and *when a device is willing to wake up* is a question only Android's WorkManager and iOS's BGTaskScheduler can answer. The product decision — *how often is it worth draining* — belongs to a composition root, which is the one layer that knows both.

## A task is a name, not a function

This is the shape everything else here follows from, and it is imposed by the platforms rather than chosen.

The operating system starts the work in a **second isolate**, long after the scheduling call returned, with a fresh Dart heap: no container, no open database, no widgets. A closure could not survive the trip, so what is scheduled is a `String` an app chose and the app registers one entry point that decides what each name means.

That splits the capability in two, and only one half lives here:

| | Where it lives | Exercised here? |
|---|---|---|
| Scheduling | this package | yes — sixteen tests against the plugin's platform interface |
| The entry point the system calls back into | `apps/*`, a top-level function carrying `@pragma('vm:entry-point')` | no — see below |

## What this repository cannot exercise, and says so

An entry point needs `apps/*/android/` and `apps/*/ios/` to exist, `Workmanager().initialize(...)` to be called from a real `main`, and a native process to invoke it. The specification this repository is built from [explicitly excludes iOS and Android builds](../../../docs/HEXAGONAL_MONOREPO_PROJECT_SPEC.md), so none of that is here — the same gap `codemagic.yaml` and `fastlane/Fastfile` state at the top of themselves.

What the apps *do* carry is the half that is testable: `drainInBackground` in each composition root is an ordinary function over a container, with ordinary tests, and the un-runnable part is the six-line dispatcher that builds the container and hands it over. **The decision is tested; the native entry is not.** `flutter create --platforms=android,ios .` inside an app is the step that closes it, and it is the same step that closes `onBackgroundMessage`.

## The period is a floor, and the adapter raises it rather than passing it on

WorkManager refuses to repeat faster than fifteen minutes and applies that silently. An app that asked for five would get fifteen and believe it had five, so `WorkManagerScheduler` raises anything below `BackgroundScheduler.minimumInterval` before the call — the number that reaches the platform is the number this package can defend.

iOS is looser than a floor rather than tighter: BGTaskScheduler decides when a device is idle enough and may not run a task for days. Work whose correctness depends on running at a particular time does not belong here at all, which is why nothing in this product depends on it — a drain that never happens loses no work, because the outbox is durable.

## `update`, not `keep`

A periodic task is registered with `ExistingPeriodicWorkPolicy.update`. `keep` — the policy that sounds safer — leaves the period the *first* install asked for in force forever: a shipped change to the interval would never take effect on a device that had run the old build.

## What it may depend on

`core_kernel`, the Flutter SDK, `workmanager` and `workmanager_platform_interface`.

The adapter takes the plugin's *platform interface* through its constructor rather than reaching for `Workmanager()`, which is the decision every adapter in `platform/` makes: it is rule 1.2.7 (no global inside a package), and it is what lets sixteen tests run on a machine with no Android and no iOS.

## What must never live here

- **A product name.** `peyk.sync.drain` is a string a composition root chose. A `SyncTask` enum here would be this package learning what a sync is.
- **A retry policy.** The failure cases say what happened; deciding to try again is the caller's. `sync` already has the only retry policy in the workspace and it is not this one.
- **The entry point.** It needs a container, and a container is an app.
- **A `core_ports` dependency.** Nothing here needs a `Clock`: scheduling is expressed in durations from now, which is what both platforms take.
