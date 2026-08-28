# Resolved: a facade forced every app to bind every port

**Status:** resolved on 2026-08-28, in phase 8, by the two commits titled
`refactor(routing): one driving port per audience…` and
`refactor(delivery): three driving ports…`.

**Where the rule now lives:** [`DEPENDENCY_RULES.md` §2.3, "How wide a driving port is"](../DEPENDENCY_RULES.md), with its non-mechanical half listed in §8. `docs/ARCHITECTURE.md` does not exist yet; when it is written, scenario 5 has to carry the summary in section 4 of this file and this file becomes a footnote to it.

This file is kept rather than deleted because the *wrong* answer it started from is half the lesson.

---

## 1. What was observed, and what phase 7 got wrong

The observation was right: `app_dispatcher` bound `DeviceLocationStream` over the desk's GPS and `HttpGeoFence` over the desk's position, and neither could give a true answer.

The **explanation was wrong**. Phase 7 recorded them as "safe only because nothing on a dispatcher's screens calls those use cases". Phase 8 checked, and found:

- `apps/app_dispatcher/lib/src/router/dispatcher_routes.dart` mounts `RouteScreen` at `routing.courierRoute`.
- `RouteScreen.initState` calls `RouteController.load`.
- `load` called `recalculateOnDeviation` — because routing had no read-only "what is planned", and the controller's own doc comment argued it "should not grow one for this".

So the screen *did* call it. What actually kept the desk's GPS out of the answer was unrelated: `RecalculateOnDeviation` reads the route cache first, `app_dispatcher` binds a **local** `KeyValueRouteCache`, and a desk's local cache is normally empty, so the use case returned before reaching the position. That is an accident of adapter choice, not a guarantee — and it disappears the moment a desk gets the remote route cache it obviously wants.

**The lesson to carry:** "nothing calls it" is not a guarantee. It is a claim about every call site in the workspace, present and future, and this one was already false when it was written.

## 2. What the literature said

Searched first, as the instruction that opened this note required.

- **ISP, in its original form** (Martin, the Xerox `Job` class): a fat class used by every client made each client depend on methods it did not use, and the cost was paid in build and deployment. Canonical statement: *"Many client-specific interfaces are better than one general-purpose interface."* `RoutingFacade` was that class.
- **CRP — the Common Reuse Principle** (*Clean Architecture*, ch. 13) is ISP's package-level counterpart and is the one that actually governs a 73-package workspace: *don't force users of a component to depend on things they don't need*. The harm here was transitive and visible in a `pubspec.yaml`.
- **Fowler, `RoleInterface` vs `HeaderInterface`.** A header interface mirrors one class's public methods. `RoutingFacade` was one, and its own doc comment admitted it — *"It is not called `RoutingFacadeImpl`"*. Fowler: *"I much prefer role interfaces, so I suggest pushing towards them as much as you can."*
- **Cockburn.** A port is *"the purpose of the conversation"*, and he favours a small number of them. The counter-evidence had to be taken seriously: his Figure 2 shows a test suite, a person, a remote application and a local one driving **one** port through four adapters. But that figure varies the *technology*, and the canonical port list in the pattern's own description includes a separate **administration** port — a different actor with a different purpose, not a different transport.
- **Graça**, the strongest opposing quote: *"a port is a consumer agnostic entry and exit point."* Resolved rather than dismissed: consumer-agnostic means **technology**-agnostic. Two audiences that differ in how they connect share a port; two audiences that differ in what they are permitted or physically able to do are two conversations.
- **CQS** (Meyer) turned out to be the other half of the problem rather than an alternative to it. See §1: a screen was asking a question by issuing a command.

## 3. The decision

Both features got one driving port per audience, drawn where a driven port stops being answerable.

| routing | operations | composed by |
|---|---|---|
| `RoutePlanning` | `planRoute`, `currentPlan`, `changes` | both apps |
| `RouteSupervision` | `resequence` | `app_dispatcher` |
| `RouteFollowing` | `nextStop`, `recalculateOnDeviation` | `app_courier` |

| delivery | operations | composed by |
|---|---|---|
| `DeliveryExecution` | `startAttempt` | `app_courier` |
| `DeliverySettlement` | `completeWithProof`, `failWithReason` | both apps |
| `DeliveryHistory` | `attemptsFor`, `changes` | both apps |

`app_harness` composes all six, which is what makes it the one place the split is legible as a split rather than as a subset.

**Candidate 4a was right and incomplete.** Splitting the interfaces alone would have left every app building the same coordinator, whose constructor demanded every use case. `identity` was the precedent for interface segregation and *not* for composition segregation — `IdentityCoordinator` implements three ports from one constructor. Routing and delivery needed both halves: three coordinators each, sharing a `RouteChannel` / `DeliveryChannel` because the change stream is one fact that three interfaces report.

**Candidate 4b was not an alternative axis, it was a missing method.** `CurrentPlan` is the query the screen should always have had. The read/write line does not fall where the audience line falls — `resequence` and `recalculateOnDeviation` are both writes performed by different people — so CQS did not decide the split, but ignoring it is what produced the defect.

**Candidate 4c was rejected, and the reason generalised into a rule.** `DeskAlertChannel` answers a *capability* the device lacks, on a **driven** port, where the domain still asks and "cannot" is a real answer. `recalculateOnDeviation` on a desk is an absence of *intent*, on a **driving** port, where nobody asks and a documented refusal is unreachable code standing in for a compile-time fact. §2.3 of the dependency rules is that distinction.

## 4. Acceptance criteria, checked

1. `app_dispatcher/pubspec.yaml` has no `location_service` and no `geolocator_platform_interface` — **done**.
2. `DispatcherPlatform` has no `location` field; it is five fields where it was six — **done**.
3. No doc comment in `apps/app_dispatcher/` says a port is bound and never called; the README section is rewritten around what replaced it — **done**.
4. All three `container_test.dart` files pass, and two of them gained the stronger assertion: `app_dispatcher` asserts `RouteFollowing` and `DeliveryExecution` are **not registered**, `app_courier` asserts the same of `RouteSupervision` — **done**.
5. `arch_check` clean at 73 packages; `dart analyze --fatal-infos --fatal-warnings` clean; the affected suites green — **done**.
6. The reasoning is in `DEPENDENCY_RULES.md` §2.3 and in this file. `docs/ARCHITECTURE.md` still owes scenario 5 the summary — **outstanding, and the only thing left of this note**.

## 5. What was ruled out and stayed ruled out

Unchanged from the phase 7 note: widening a rule in §2, nullable ports in a coordinator, a throwing stub, a `_testing` fake in a product app, or splitting the apps. One more can be added now:

- **Writing `RemoteLocationStream` and a server-side geofence.** It would have made the symptom disappear and left the contract exactly as coupled — every app still binding every port, and a desk still holding an interface declaring operations it cannot perform. It may still be worth building for its own sake, because a dispatcher genuinely wants to see where a van is. It would not have closed this note.
