# Research: a facade forces every app to bind every port

**Status:** open. Carried from phase 7 into phase 8.
**Opened:** 2026-08-28, at the `phase-07` tag.
**Owner of the next step:** whoever starts the phase 8 session. Read this file *before* touching `docs/ARCHITECTURE.md` — the answer changes what that document says about facades.

This is a research note, not a rule. Nothing here is binding until it lands in [`DEPENDENCY_RULES.md`](../DEPENDENCY_RULES.md) or [`CLAUDE.md`](../../CLAUDE.md) through the process §9 of the dependency rules describes.

---

## 1. What was observed

`app_dispatcher` binds two adapters that would produce wrong answers if anything called them. They are safe only because nothing on a dispatcher's screens does.

| Port | Adapter bound | What it actually reads | Why that is wrong at a desk |
|---|---|---|---|
| `LocationStreamPort` | `DeviceLocationStream` | this device's GPS | recalculating a *courier's* route against the *desk's* position |
| `GeoFencePort` | `HttpGeoFence` | this device's position, checked server-side | asking whether the desk is at the consignee's door |

Evidence, at `phase-07`:

- `packages/features/routing/routing_application/lib/src/routing_coordinator.dart:24` — `RoutingCoordinator` requires `_recalculate`.
- `packages/features/routing/routing_application/lib/src/recalculate_on_deviation.dart:43` — which requires a `LocationStreamPort`.
- `packages/features/delivery/delivery_application/lib/src/delivery_coordinator.dart:26` — `DeliveryCoordinator` requires `_startAttempt`.
- `packages/features/delivery/delivery_application/lib/src/start_attempt.dart:46` — which requires a `GeoFencePort`.
- `apps/app_dispatcher/lib/src/di/dispatcher_features.dart:211` and `:418` — the two bindings, with the seam named in their doc comments.

## 2. The sharper framing, found while writing this note

The constructor is the *symptom*. The cause is one layer up, in the contract.

```dart
// packages/features/routing/routing_api/lib/src/routing_facade.dart
abstract interface class RoutingFacade {
  Future<Result<RoutePlan, RoutingFailure>> planRoute({...});        // both audiences
  Future<Result<RoutePlan, RoutingFailure>> resequence({...});       // dispatcher only
  Future<Result<StopId?, RoutingFailure>> nextStop({...});           // courier only
  Future<Result<RoutePlan, RoutingFailure>> recalculateOnDeviation({...}); // courier only
  Stream<RoutePlan> changes();                                       // both
}
```

`RoutingFacade` declares operations **no dispatcher can perform** and `DeliveryFacade` declares operations **no dispatcher can perform**. A composition root that wants any of the interface must supply all of it, so it must bind every port every use case behind it needs.

So the question is not "how does an app avoid binding a port" but **"is one facade per feature the right granularity when a feature has two audiences?"**

This also reframes the cost. It is not only two odd bindings in one app:

- `app_dispatcher` compiles in `location_service` and `geolocator_platform_interface` for use cases it never calls.
- `DispatcherPlatform` carries a `GeolocatorPlatform` field whose doc comment says it should not be there.
- The guarantee that this is safe is a *runtime* one — "no screen calls it" — in a repository whose entire claim is that its guarantees are compile-time.

## 3. What has already been ruled out, and why

Do not re-propose these without new information.

- **Widen a rule in §2.** Nothing here is a dependency violation. `arch_check` is clean at 73 packages and correctly so; the problem is a contract's shape, not an edge.
- **Make the ports nullable or optional in the coordinator.** A facade whose behaviour depends on which collaborators an app happened to pass is a facade with a hidden mode, and the failure moves from "wrong answer" to "silent no-op".
- **Bind a throwing stub in `app_dispatcher`.** Rule 1.2.9 — no exception crosses a port boundary — and it converts a compile-time question into a crash.
- **Bind a fake from `_testing` in the product app.** `app_dispatcher` already does this once, for `InMemoryOutboxStore`, and that is defensible because the specification's table names it and the contract kit runs against it. Doing it to paper over a shape problem is a different thing.
- **Split the *apps* further.** The number of apps is fixed by §3 of the specification.

## 4. Candidate directions, to be checked against the literature

Written from memory in phase 7 and **not researched**. The first job of the next session is to find what the literature actually says, then decide. Treat these as hypotheses to falsify.

### 4a. Role interfaces instead of one header interface

Split `RoutingFacade` into the roles its two audiences actually play — something like `RoutePlanning` (both), `RouteFollowing` (courier), `RouteSupervision` (dispatcher). One coordinator may implement several, exactly as `IdentityCoordinator` already implements `IdentityFacade`, `SessionReader` and `PermissionChecker`.

**The precedent is already in this repository**, which is the strongest argument for it: `identity` solved this in phase 4 and nobody called it a facade problem. `app_harness`'s container test asserts the three registrations resolve to one object.

To research: Fowler's *RoleInterface* vs *HeaderInterface*; the Interface Segregation Principle as originally argued (Martin, the Xerox printer case); whether hexagonal-architecture writing treats a driving port as one-per-actor. **Cockburn's own framing of ports as "one per conversation type / per actor" is the specific thing to check** — if that is what he says, this is not a new idea and the repository has been under-applying its own architecture.

### 4b. Separate the read model from the write model

`nextStop` and `changes()` are reads; `planRoute` and `recalculateOnDeviation` are writes. `reporting` already demonstrates a read model that accumulates from events (phase 6). A dispatcher may want only the read half of routing.

To research: CQS as distinct from CQRS; whether the split falls on the same line as 4a or a different one. If both splits are defensible, which one the *audience* boundary follows matters more than which one is tidier.

### 4c. Leave it, and make the absence explicit in the contract

A `RoutingFacade` whose `recalculateOnDeviation` returns a documented failure when the app has no device position. This is the "null object with an honest answer" shape `DeskAlertChannel` already uses in `app_dispatcher` — and that precedent is worth taking seriously, because it was judged correct three days ago for the same class of problem.

The difference to argue about: `DeskAlertChannel` answers a *device capability* the desk lacks, which is a fact about the machine. Recalculating somebody else's route is a fact about the *audience*. If those are different kinds of absence, they want different solutions; if they are not, 4c is the consistent answer and 4a is over-engineering.

**Do not assume 4a wins because it is more architectural.** The question this repository exists to answer is which one a reader learns more from.

## 5. Constraints any answer must satisfy

- A `_presentation` package may depend on its own `_api` and foreign `_api` only (§2). Any new interface goes in the feature's `_api`.
- `_api` holds no implementation (S8). Splitting a facade adds interfaces, never a base class with behaviour.
- Every port method returns `Result` where it can fail, a plain value where it cannot (CLAUDE.md §3). A split must not introduce a failure branch that can never be taken.
- Contract kits in `_testing` are held against every implementation. A split changes what the kits are held to, so `routing_testing` and `delivery_testing` change with it.
- Whatever lands must keep all three container tests passing and must let `app_dispatcher` **stop** depending on `location_service` — that is the observable outcome, and it is the acceptance criterion below.

## 6. Acceptance criteria for closing this note

1. `app_dispatcher/pubspec.yaml` has no `location_service` and no `geolocator_platform_interface`.
2. `DispatcherPlatform` has no `location` field.
3. No doc comment in `apps/app_dispatcher/` says a port is bound and never called. The four places listed in §7 are gone or rewritten.
4. All three `container_test.dart` files pass unchanged in intent — every facade an app composes still resolves.
5. `arch_check` clean; `dart analyze --fatal-infos --fatal-warnings .` clean; `melos run test` green.
6. The decision and its reasoning are written into `docs/ARCHITECTURE.md` under the scenario 5 heading, and this file is deleted or marked resolved with a pointer to it.

## 7. Where the current workarounds are

Clean these up when the note is closed:

- `apps/app_dispatcher/lib/src/di/dispatcher_features.dart:211` — `locationSource`, doc comment naming the seam.
- `apps/app_dispatcher/lib/src/di/dispatcher_features.dart:409` — `start`, "a dispatcher never does".
- `apps/app_dispatcher/lib/src/di/dispatcher_features.dart:418` — `fence`, "the second of the two ports a desk cannot honestly answer".
- `apps/app_dispatcher/lib/src/di/dispatcher_platform.dart` — the `location` field's doc comment.
- `apps/app_dispatcher/README.md` — the section "Two ports a desk cannot honestly answer".
- `CLAUDE.md` §10 — "The one thing phase 7 found and did not fix".

---

## Notes to myself, for the session that picks this up

**Research first, code second.** The user's instruction at the end of phase 7 was explicit: find the literature's answer, then integrate it. Do not open an editor before the search. The last time an architectural question came up mid-phase — where `PeykIntent` belongs — the answer came from the constitution rather than from taste, and it was better for it.

**Search terms worth trying:** `hexagonal architecture one port per actor`, `Cockburn ports and adapters primary port granularity`, `role interface vs header interface Fowler`, `interface segregation principle facade`, `application service granularity DDD`, `use case interactor per use case vs facade`. Vaughn Vernon's *Implementing DDD* on application services, and Cockburn's own 2005 article, are the two primary sources most likely to settle 4a.

**The strongest evidence is in this repository already.** `IdentityCoordinator` implements three interfaces and every app registers it three times. If the literature says "one port per actor", then identity is the pattern and routing/delivery are the exceptions — and phase 8 is applying an existing decision rather than making a new one. Check that framing before proposing anything novel.

**Watch for the wrong fix.** Writing `RemoteLocationStream` and a server-side geofence adapter would make the symptom disappear and leave the contract exactly as coupled. It might still be worth doing for its own sake — a dispatcher genuinely wants to see where a van is — but it does not close this note, and doing it *instead* of the research would be the mistake.

**Do not let this block phase 8's other work.** `test_runner`, `dep_graph`, the CI files and `docs/ARCHITECTURE.md` are the phase's scope. This note is the first item because the answer changes what `ARCHITECTURE.md` says about facades and scenario 5 — not because the rest waits on it.

**If the research is inconclusive, say so and pick 4c.** An honest "the literature does not settle this, and here is why we chose the smaller change" is a better artifact than a speculative refactor across four packages. The repository's value is that its decisions are argued, not that they are maximal.
