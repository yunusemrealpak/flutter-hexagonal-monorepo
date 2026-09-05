# Dependency rules

This document is the authoritative dependency constitution for the workspace. It is written to be mechanically checkable: from phase 3 onwards `tooling/arch_check` reads `tooling/arch_check/rules.yaml`, which encodes exactly what is written here. If the two ever diverge, this document is the specification and `rules.yaml` is the bug.

Until `arch_check` exists (phases 0–2), every rule is verified by hand and the commit body states which rule was verified.

---

## 1. How a package's type is determined

Rules are applied per *package type*, and a package's type is derived from its path and name — never from its contents. This is deliberate: type inference must be cheap, total, and impossible to game.

| Type | Matcher |
|---|---|
| `core_kernel` | path `packages/core/core_kernel` |
| `core_ports` | path `packages/core/core_ports` |
| `core_navigation` | path `packages/core/core_navigation` |
| `core_testing` | path `packages/core/core_testing` |
| `feature_api` | path `packages/features/<feature>/` and name ends with `_api` |
| `feature_application` | path `packages/features/<feature>/` and name ends with `_application` |
| `feature_infrastructure` | path `packages/features/<feature>/` and name ends with `_infrastructure` |
| `feature_core` | path `packages/features/<feature>/` and name ends with `_core` |
| `feature_presentation` | path `packages/features/<feature>/` and name contains `_presentation` |
| `feature_testing` | path `packages/features/<feature>/` and name ends with `_testing` |
| `platform` | path `packages/platform/` |
| `design_tokens` | path `packages/design/design_tokens` |
| `design_system` | path `packages/design/design_system` |
| `tooling` | path `tooling/` |
| `app` | path `apps/` |

A package whose path and name do not resolve to exactly one type is itself a violation (`unknown_package_type`). There is no default.

**And so is depending on one.** An untyped package is left out of the dependency graph, because no row of §2 applies to it. Every edge into it is reported as `forbidden_dependency` all the same: without that, a package the constitution cannot reason about would be indistinguishable at every call site from a package on pub, and the classic mistake — a `shared` package two features both reach for — would show up once, on the package, while everything that depended on it looked clean.

**Which name.** The matchers read the *directory* name, not the pubspec's `name:` field. Rule S5 below requires the two to be equal, so in a healthy workspace the choice is invisible; it only matters when they disagree. Believing the pubspec there would drop the package out of every type and replace one obvious violation — `name_mismatch` — with silence about the other twenty rules, so the filesystem wins and the mismatch is reported on its own.

**Owning feature.** For every `feature_*` package, the owning feature is the directory name under `packages/features/`. `shipments_presentation_courier` lives in `packages/features/shipments/`, so its owning feature is `shipments` and its own `_api` is `shipments_api`.

---

## 2. Allowed dependencies

Read this as a whitelist. Any dependency edge not listed is a violation (`forbidden_dependency`). "Own `_api`" means the `_api` package of the same owning feature; "foreign `_api`" means any other feature's `_api` package.

| Package type | May depend on | May **not** depend on |
|---|---|---|
| `core_kernel` | nothing — not even the `flutter` SDK, not one third-party package | everything |
| `core_ports` | `core_kernel` | everything else |
| `core_navigation` | `core_kernel` | everything else |
| `core_testing` | `core_kernel`, `core_ports`, `core_navigation` | any feature, any platform package |
| `feature_api` | `core_kernel`, `core_ports`, foreign `_api` | its own siblings, any implementation package, `flutter` |
| `feature_application` | own `_api`, `core_kernel`, `core_ports`, foreign `_api` | any `_infrastructure`, any `_presentation`, any `platform/*`, `flutter` |
| `feature_infrastructure` | own `_api`, `core_kernel`, `core_ports`, `platform/*` | any `_application`, any foreign feature package including foreign `_api` |
| `feature_core` | own `_api`, `core_kernel`, `core_ports`, `platform/*`, foreign `_api` | any `_application`, any `_infrastructure`, any `_presentation` |
| `feature_presentation` | own `_api`, foreign `_api`, `core_kernel`, `core_navigation`, `design_system` | any `_application`, any `_infrastructure`, any `_core`, any `platform/*` |
| `feature_testing` | own `_api`, `core_kernel`, `core_ports`, `core_testing`, foreign `_api` | any implementation package |
| `platform` | `core_kernel`, `core_ports`, the `flutter` SDK | any feature package, any other `platform/*` |
| `design_tokens` | the `flutter` SDK only | everything else |
| `design_system` | `design_tokens`, `core_kernel`, the `flutter` SDK | any feature package, any `platform/*` |
| `tooling` | third-party Dart packages only | every product package in `packages/` and `apps/` |
| `app` | anything | nothing |

Third-party packages are unrestricted except where §4 forbids them explicitly.

### 2.0 What "depend on" means

The rules in this section apply to the `dependencies:` block of a pubspec and to imports under `lib/`. Two things are deliberately outside their scope:

- **`dev_dependencies:` used only by `test/`.** Every package needs a test harness, and `package:test` is not an architectural dependency — it never ships, and nothing under `lib/` may import it. `core_kernel` therefore has `test` in `dev_dependencies` while still having an empty `dependencies` block, and that is not a violation of "depends on nothing". `arch_check` reads `dependencies:` for edge validation and scans `lib/` for imports; a package that imports a dev dependency from `lib/` is a violation (`dev_dependency_in_lib`).
- **`build_runner` and generator packages.** They are dev dependencies for the same reason: they run at build time and produce source, they are not part of the package's runtime surface.

### 2.1 Notes on the edges people get wrong

**A `feature_api` may name a foreign `_api`'s identifiers, and nothing else.** The row permits the edge and the edge is worth having: two features with two spellings of "who a courier is" reconcile in whichever adapter noticed first. What it does not permit is borrowing a foreign *model*. An `ActorId` or a `ShipmentId` is a single value whose whole content is "which one"; an `AddressPoint` is three fields, a validation and a label — a concept `shipments` owns, which `routing` would then be carrying around.

The test is mechanical. If the type has behaviour, or more than one field, it is a model and the consuming feature declares its own. If it is an identifier, it crosses.

This is the rule the wider literature states as *reference other contexts by identity*, and phase 5 found it the expensive way. `routing_api` gave `Stop` an `AddressPoint`, so every stop had to answer "do you have coordinates?" on every read, `StopNotGeocoded` ended up in the contract three optimisers are held to, and `routing_infrastructure` could not build a `Stop` without reaching for `shipments_api`. Replacing it with routing's own `GeoPoint` plus a label removed all three at once — and made the invalid state unconstructible, which is what the borrowed model had been hiding.

**`feature_infrastructure` may not depend on a foreign `_api`.** An adapter translates between one feature's ports and one technology. If it needs a concept from another feature, the concept belongs in its own `_api` and the *use case* — not the adapter — should be doing the crossing.

The case that looks like an exception and is not: an adapter has to rebuild the identifiers its *own* contract is expressed in. `shipments_infrastructure` maps a row into `ShipmentStatus.assignedToCourier(ActorId)` and may not see `identity_api`. The answer is a reader published by the owning `_api` — `CourierReference.parse` in `shipments_api` — which is allowed to see identity, returns *shipments'* failure type, and leaves the adapter depending on nothing foreign. That is an anticorruption layer placed in the consuming feature's own contract, and it is why this row has never needed widening.

**Pressure to widen this row is a symptom, not a case.** Both times it has appeared, the cause was upstream: a foreign model had crossed where an identifier should have, or a reader was missing from the owning `_api`. Fix that and the row stops chafing.

**`feature_application` may not depend on `platform/*`.** Platform packages are driven adapters. An application package that reaches for one has stopped being pure Dart and has stopped being testable without a device.

**`feature_core` is the widest row here, and the rules it does not enforce are the ones its packages have to keep by hand.** It may see both `platform/*` and a foreign `_api` — the only feature row that carries both — because a reduced-split feature holds the application and infrastructure halves of a hexagon in one package. Everything about the *shape* is unchanged: the driven port is still declared in `_api`, the use cases still depend on it and not on a store, and the adapter still implements it. What is missing is the compiler. In a full split, an import from a use case to the adapter beside it is a `forbidden_dependency`; in a `_core` package the same import compiles and nothing complains.

Phase 6 kept three disciplines by hand across seven features, and every `_core` README states them:

- **No use case imports an adapter, and no adapter imports a use case.** Keep that and splitting the feature later is a `git mv` and two pubspecs. Break it and the split is a rewrite — which is the failure mode a reduced split is actually exposed to, and the reason it is a *starting point* rather than a discount.
- **A driven port still speaks in raw identifiers.** `arch_check` would let `KeyValuePreferencesStore` import `identity_api` and take an `ActorId`; it does not, because such an adapter could not move into an `_infrastructure` package.
- **The one place the discipline genuinely cannot be kept is worth writing down.** `IncidentDto` calls `ActorId.parse` and `ShipmentId.parse` directly and translates their failures with `mapFailure`. An `_infrastructure` package could not: it would need a reader published by its own `_api`, the way `shipments_api` publishes `CourierReference`. That file is named in `incidents_core`'s README as the one part of a later split that would not be a pure move.

**`feature_testing` may depend on a foreign `_api`, and on no implementation.** The row originally allowed neither, and the omission surfaced the first time an `_api` legally named a foreign type: `shipments_api` declares `ShipmentStatus.assignedToCourier(ActorId)`, and `shipments_testing` — whose job is to build fixtures for exactly that surface — could not write the type down. A package that may see another's public surface has to be able to name what is in it. The prohibition that matters is unchanged: a fake that depended on `payments_application` would break whenever those use cases were refactored, which is the whole reason a contract package is separate from the code that satisfies it.

**`platform/*` may not depend on `platform/*`.** This one bites in practice rather than in theory, because platform packages genuinely need each other's capabilities: `location_service`, `media_capture` and `push_messaging` all need a permission granted, and the adapter for that lives in `device_permissions`. The resolution is the same one the constitution uses everywhere else — depend on the *port*, take it through the constructor, and let an application's composition root supply the adapter. A platform package that reached for another directly would make an app that wants the camera drag in a location plugin.

### 2.2 Where a contract is declared

`core_ports` and `platform/*` both declare interfaces, and telling them apart is the question phase 2 answered. The test is what the interface speaks in.

| | `core_ports` | `platform/<name>` |
|---|---|---|
| Speaks in | the product's words | a technology's words |
| Example | `SecureStore`, `Clock`, `NetworkStatus` | `HttpTransport`, `LocationSource`, `MediaCapture`, `PushMessagingClient` |
| Bar for entry | more than one feature needs it and none of them owns it | one technology answers it, and the adapter is in the same package |
| Who may see it | anything that may depend on `core_ports` | `feature_infrastructure`, `feature_core`, `apps/*` — never `_application` |

Nothing in the product asks for "an HTTP request" or "a GPS fix". `shipments` asks for a shipment through a port in `shipments_api`; `delivery` asks whether a courier is at an address. Those are domain contracts, and a feature's `_infrastructure` answers them *using* a technology contract. The dependency table already enforces the consequence: `_application` may not depend on `platform/*`, so a use case can never see an `HttpRequest` and can never end up owning a retry policy.

A technology contract lives in the same package as its adapter, together with the fake that stands in for it. A fake belongs with the contract it imitates — which is why `FakeHttpTransport` ships from `http_dio` and not from `core_testing`, while `InMemorySecureStore` ships from `core_testing`, because `SecureStore` is declared in `core_ports`.

### 2.2.1 What `core_kernel` is allowed to hold

`core_kernel` is the one package everything may depend on, so a type added here is a type added everywhere and rule 15 of §2 of CLAUDE.md forbids adding one that is not strictly needed. The test that decides it is **whether the type carries domain meaning**.

| | Belongs in `core_kernel` | Belongs to the feature |
|---|---|---|
| Says | an operation can fail; a collection has more behind it | what failed; what the rows are |
| Example | `Result`, `Failure`, `PageOf`, `PageRequest`, `PageCursor` | `ShipmentFailure`, `ShipmentSummary` |
| Test | the same sentence for every feature | one feature's word |

"Several features would find this convenient" is *not* the test, and is how a `common` package starts. `PageOf` passes because *there are more rows and here is where to resume* is the same statement for a courier's manifest, a shipment's delivery history and a dispatcher's board — a copy per feature would be identical code in fourteen `_api` packages with fourteen chances to disagree about what an absent cursor means. `ShipmentSummary` fails it outright.

**Two things a type in here has to do that a type in a feature does not.**

*Pick its name defensively.* `PageOf` is not called `Page` because Flutter's `widgets` library exports a `Page`, and every presentation package imports both. `core_kernel` takes no Flutter dependency and so cannot see the collision it is causing; the innermost ring is the one package with no way of knowing what it is colliding with, and the cost of getting it wrong is a `hide` in fourteen packages.

*Own its own failure story.* A validating factory returning a `Result` needs a `Failure` to return, and `core_kernel` has no concrete one. That is a signal rather than an obstacle: a type here should be one whose invalid states are programming errors rather than user input. `PageRequest` clamps its limit for exactly that reason — there is no screen that could render "limit must be positive" and no person who could correct it.

### 2.3 How wide a driving port is

Section 2.2 says where a contract is declared. This says how much of a feature one contract may cover, and it is the question phase 8 answered.

A driving port is **one audience's conversation with the feature**, not the feature's whole public surface. Two audiences share a port when they ask the same thing through different technology — Cockburn's own example is a screen, a test suite and a remote system driving one port through three adapters. They do **not** share a port when one of them cannot perform an operation at all, because no adapter fixes that.

The test that draws the line is mechanical enough to apply without argument: **look at the driven ports behind each operation, and ask whether every audience can answer them honestly.**

| | Absence of *capability* | Absence of *intent* |
|---|---|---|
| Which side | a driven port | a driving port |
| Example | a desk has no push client | a desk never stands at a consignee's door |
| The right answer | an adapter that declines — `DeskAlertChannel` returns `AlertsRefused` | the operation is not on the interface that audience holds |
| Why | the domain still *asks*, and "cannot" is a real answer | nobody asks, so a refusal is unreachable code standing in for a compile-time fact |

Two consequences are easy to get wrong:

**Splitting the interface is not enough on its own.** `IdentityCoordinator` implements three ports from one constructor, which segregates what a caller may ask and not what a composition root must supply. If an app must still build an object whose constructor demands a use case it cannot answer, nothing has been gained. The implementation splits with the interface, and a shared fact between the halves — a change stream — becomes an explicit collaborator (`RouteChannel`, `DeliveryChannel`) rather than a field on whichever coordinator happens to be registered.

**A query must not be answered by a command.** A screen that opens on a route asked `recalculateOnDeviation` because routing had no read; that operation reads the caller's position and may replace the plan. Where an audience needs to *see* something, the port owes it a query — `RoutePlanning.currentPlan` — and the failure of that rule is what let a desk replan a courier's afternoon from the office.

The cost of the rule is more interfaces. The benefit is the one this repository exists to make visible: `app_dispatcher`'s `pubspec.yaml` no longer lists `location_service`, and its container test asserts that `RouteFollowing` and `DeliveryExecution` are *not registered* — the Common Reuse Principle turned into a check.

### 2.4 Who is allowed to navigate

Sections 2.2 and 2.3 draw a feature's ports. This draws the one edge a *screen* is tempted to add, and the answer is that it may not: **navigation is an app's decision, and a presentation package reports outcomes rather than destinations.**

The reason is the dependency table above, read carefully. Route names are declared in presentation packages, and a presentation package may not import another feature's presentation package. So a screen that wanted to send somebody to another feature could not name that destination — it could only spell it as a string. That is a dependency the compiler cannot see, `arch_check` cannot see, and a rename breaks at runtime.

The alternative people reach for next is a navigation interface in `core_navigation` with an app-supplied adapter. It has to declare a method per destination, so the package every presentation package depends on would name every feature — §2.1's forbidden `shared` package, wearing a router's clothes.

What is left is what this repository already does for a capability a screen may not have. `ProofCaptureScreen` takes `onCaptureSignature` because §1.1 forbids a presentation package from seeing `platform/*`; the app supplies the capture, and the button is drawn only when it is supplied. A flow step is the same shape:

| | The screen offers | The app decides |
|---|---|---|
| A capability it may not depend on | `onCapturePhoto`, `openSystemSettings` | which camera, which settings page |
| A destination it may not name | `onSettled(DeliveryAttempt)` | which screen is next |

**The capability row is not a loophole for smuggling a port in as a function**, and the settings screen's alerts section is where the line is easiest to see. That section performs two operations. *Turning alerts on* arrives as `NotificationsFacade`, a real port, because a foreign `_api` is an edge the table grants and because the decision behind it — whether this device is open to alerts — belongs to a feature. *Opening the operating system's settings page* arrives as a `Future<bool> Function()`, because `PermissionRequester` lives in `core_ports` and this row has no `core_ports` edge. The test is whether the thing being asked for is a **decision the product owns** or a **mechanism the platform owns**: the first is a port and belongs to a feature, the second is a callback and belongs to the app.

Three consequences worth stating, because each has been got wrong somewhere:

**The callback carries what happened, never where to go.** `onSettled(DeliveryAttempt)` is an outcome; `onGoToPayments()` is a destination with a callback's syntax, and it puts the flow back inside the screen. The value it carries comes from the screen's own `_api`, so no dependency is added.

**A capability callback answers in the screen's own vocabulary, and it has to be wide enough to act on.** `onCapturePhoto` answered `PhotoEvidence?` until 2026-09-02, and the null collapsed three device outcomes into one: a courier who backed out, a permission that can be asked for again, and a camera switched off in the system settings. Only the last has a way out — the settings page this same row supplies — so the narrow return type made the one actionable case the one nothing could act on. It answers `Result<PhotoEvidence, CaptureRefusal>` now, with `CaptureRefusal` declared in `delivery_api` beside the evidence it stands in for. **The test for the width: enumerate what the app can come back with, and ask whether the screen would draw each one differently.** A nullable value can express two answers, and a device capability rarely has only two.

**Entry stays a URL.** A notification tap, a scanned barcode and a pasted link cannot invoke a callback. `RouteDefinition.path` is the contract for arriving; the callback is the contract for continuing. Guards — session and permission — belong with arrival, in the app's redirect.

**The flow belongs to the audience, not to the feature.** A courier goes manifest → route → door → money; a dispatcher opening the same delivery screen goes nowhere near a door. That is §2.3 one level up, and the only place that knows which audience is running is the app that mounted the features.

**A modal that answers a value is still navigation, and `A6` is right to say so.** `PeykSignaturePanel` in `design_system` first pushed its own route and popped it with the ink — no destination named, no feature imported, nothing the paragraphs above are about. `A6` refused it anyway, because it lists `Navigator.of` and lives outside `apps/`. That is a mechanical rule over-catching a case, which is the moment to check whether the rule or the code is wrong: here the code was. A component that decides how it is presented is a component that cannot be presented another way — the same pad belongs in a dispatcher's side panel one day — and an app that pushes a route is going to own popping it whatever the component thinks. The panel reports `onSigned` and `onCancelled`; the app decides both mean *pop*.

Rules `I8` and `A6` in §4 and §5 make this mechanical. Both were written while the workspace had zero violations of either, which is the point: the first one to appear is a mistake rather than a migration.

---

## 3. Structural rules

| ID | Rule | Violation code |
|---|---|---|
| S1 | Every package has a barrel at `lib/<package_name>.dart`. An `app` has entry points instead — see below. | `missing_barrel` |
| S2 | That barrel is the only `.dart` file directly under `lib/`. Everything else lives under `lib/src/`. | `stray_lib_file` |
| S3 | No file imports `package:<other_package>/src/...`. Within its own package, imports are relative — see the convention in CLAUDE.md section 3 — so `package:*/src/` appearing anywhere in the source is a violation with no exceptions to weigh. | `deep_import` |
| S4 | A barrel re-exports and does nothing else: it declares no type of its own, and it does not re-export another package's `package:` URI. | `barrel_leak` |
| S5 | The `name:` in `pubspec.yaml` equals the directory name. | `name_mismatch` |
| S6 | The package path is registered in the root `pubspec.yaml` `workspace:` list, and the package declares `resolution: workspace`. | `unregistered_package` |
| S7 | The dependency graph is acyclic. | `dependency_cycle` |
| S8 | An `_api` package contains no implementation class — no class that implements or extends a port declared in the same package, and no concrete adapter. The second half is a naming heuristic and is skipped in generated files; see below. | `implementation_in_api` |

**S1 and S2 mean something different in an `app`, and phase 7 is where that surfaced.** Both rules were written for a package with dependents: "the public surface is one barrel named after the package" is a promise to whoever imports it. Nothing imports an app. What an app has instead is an *entry point*, and Flutter's tooling looks for it directly under `lib/` — `flutter run` defaults to `lib/main.dart`, and a multi-flavour app selects one with `flutter run -t lib/main_prod.dart`. Several files directly under `lib/` is that ecosystem's shape rather than a smell, and the phase 7 specification asks for flavour configuration explicitly.

So on the `app` row: S1 requires at least one file matching `^main(_[a-z0-9]+)*\.dart$`, S2 treats every other file directly under `lib/` as a stray exactly as before, and **S4 does not apply at all** — an entry point's whole job is to declare `main`, and "a barrel declares nothing of its own" would forbid the one thing it exists for. `rules.yaml` spells this out as `structure.entry_point`.

The alternative was to put `main()` inside a barrel and let S4 slide, which would have traded a rule that is precise on nine package types for one that is vague on ten.

**S8 has two halves, and only one of them reads a generated file.** "A class that implements a port declared in this package" reads a *declaration*: a builder that emitted an adapter into a contract package emitted a real violation, whoever configured it, so generated files are checked. "A concrete class whose name ends in `Impl`, `Adapter`, `Repository`, `Service` or `Client`" reads a *name*, and a generator names its own output — `freezed` emits a `_$<Type>CopyWithImpl` for every class it touches, so an `_api` package with one generated union would report a violation per generated type and go on doing it until somebody turned the rule off. The naming half is therefore skipped in generated files, for the same reason §5 exempts them from the ambient-API rules: the name is not the developer's choice. `rules.yaml` spells this out as `suffixes_skip_generated`.

S3 is additionally enforced by the analyzer: `implementation_imports` is promoted to `error` in the root `analysis_options.yaml`. Because intra-package imports are relative, it is also verifiable by hand in one command:

```bash
grep -rn "package:[a-z_]*/src/" packages/ apps/   # any output is a violation
```

---

## 4. Forbidden imports

| ID | In package types | Forbidden import | Why | Violation code |
|---|---|---|---|---|
| I1 | `core_kernel` | any package import at all under `lib/` | it is the innermost ring; everything else can depend on it, so it must be able to depend on nothing. `dev_dependencies` used by `test/` are out of scope — see §2.0 | `kernel_dependency` |
| I2 | `feature_api`, `feature_application` | `package:flutter/...` | these packages are pure Dart, which is what keeps the ~80% of the suite that lives here fast | `flutter_in_pure_dart` |
| I3 | `feature_api`, `feature_application` | `package:dio/...`, `package:drift/...`, `package:http/...`, `package:shared_preferences/...`, and any other transport or persistence library | technology choices belong in adapters | `technology_in_domain` |
| I4 | `feature_api` | `package:json_annotation/...` | DTOs are an infrastructure concern; see §6 | `serialization_in_api` |
| I5 | every package outside `apps/` | `package:get_it/...` and any global service-locator library | dependencies arrive through constructors; the locator exists only at the composition root | `locator_outside_app` |
| I6 | every package outside `apps/` | `package:injectable/...` | annotation-based DI is app-layer only | `annotation_di_outside_app` |
| I7 | `tooling/*` | any package under `packages/` or `apps/` | tools must be able to analyze a broken workspace without being part of it | `tooling_depends_on_product` |
| I8 | every package outside `apps/` | `package:go_router/...` and any other router library | a router is an app's choice; in a presentation package it becomes every app's choice, and changing it becomes a change to fourteen packages instead of three. See §2.4 | `router_outside_app` |

---

## 5. Forbidden APIs

| ID | Forbidden call | Use instead | Violation code |
|---|---|---|---|
| A1 | `DateTime.now()` | `Clock` from `core_ports` | `ambient_clock` |
| A2 | `Random()`, `Random.secure()` | `RandomSource` from `core_ports` | `ambient_random` |
| A3 | `Uuid()` and equivalents | `IdGenerator` from `core_ports` | `ambient_id` |
| A4 | `print()`, `debugPrint()` | `Logger` from `core_ports` | `ambient_print` (`print` is also covered by the `avoid_print` lint; `debugPrint` is not, and is the spelling a presentation package reaches for) |
| A5 | `throw` or `rethrow` inside a member whose declared return type is a `Result` — directly, or wrapped in `Future`, `FutureOr` or `Stream` | return a `Result<S, F>` with a `sealed` failure | `exception_at_port_boundary` |
| A6 | `context.go`, `context.goNamed`, `context.push`, `context.pop` and their named variants, `Navigator.of`, `Navigator.push`, `Navigator.pop`, `GoRouter.of` | an outcome callback the app supplies — see §2.4 | `navigation_outside_app` |

**Matching.** A1–A4 and A6 are checked against parsed source, not against a text search. Two failure modes make the naive grep useless, and both were observed while writing the core packages in phase 1:

- **Comments quoting the rule.** `core_ports/clock.dart` documents itself with "this port exists so that no line of product code calls `DateTime.now()`". Every doc comment that explains why a rule exists trips a checker that scans raw text, and the packages most careful about the rule trip it most often.
- **Regex metacharacters.** A pattern of `DateTime.now()` with an unescaped `.` matches the declaration `DateTime now()` — the port itself — because the dot matches the space.

`arch_check` therefore walks the analyzed AST and reports method invocations and instance creations, ignoring comments and string literals entirely.

**Scope.** A1–A4 and A6 are checked in every package except `apps/*` (where the composition root supplies the real implementations) and `tooling/*` (which is not part of the product). Generated files (`*.g.dart`, `*.freezed.dart`, `*.gr.dart`, `*.config.dart`) are exempt from A1–A4, because a `DateTime` in generated output is not the developer's choice. Generated files are **not** exempt from §2 or §4: a generated file importing a package the constitution forbids is a real architectural violation regardless of who typed it. §3 applies to them too, with the single carve-out recorded under rule S8 — the half of that rule which reads a class *name* rather than a declaration, for the same reason as here.

---

## 6. Code generation rules that are machine-checked

| ID | Rule | Violation code |
|---|---|---|
| G1 | `core_kernel` contains no generated file and no `build.yaml`. Regeneration cost in the innermost ring spreads to the whole repository. | `codegen_in_kernel` |
| G2 | `json_serializable` is not enabled in any `feature_api` package's `build.yaml`, and no `json_annotation` import appears there. This is the machine check for "DTOs are never declared in `_api`". | `serialization_in_api` |
| G3 | `injectable_generator` is enabled only in `apps/*`. | `annotation_di_outside_app` |
| G4 | Every package that has generated files has a `build.yaml`, it enables at least one builder, and every builder it enables is narrowed with `generate_for`. An unconfigured package makes build_runner scan every builder, which is significant waste at 75 packages. | `unpinned_builders` |

"Disables the rest explicitly" is the intent, and it is deliberately not machine-checked: naming a builder that is not a dev dependency of the package fails the build rather than tightening it, so "the rest" is only ever the rest that is actually present. What *is* checked is the half that is decidable — a `build.yaml` exists, it turns something on, and everything it turns on is narrowed.
| G5 | Generated files are committed. `melos run gen` followed by `git diff --exit-code` is clean. | checked by `gen:check`, not by `arch_check` |

The `build.yaml` shape each package type is expected to produce:

```yaml
# <feature>_api — freezed only
targets:
  $default:
    builders:
      freezed:
        enabled: true
        generate_for:
          - lib/src/**/*.dart
      json_serializable:
        enabled: false
      source_gen:combining_builder:
        options:
          ignore_for_file:
            - type=lint
```

---

## 7. Violation output contract

Every violation `arch_check` reports carries four fields, because a rule that does not say how to fix it gets worked around instead of obeyed:

1. **code** — one of the codes in this document
2. **location** — package, and file plus line where a file is implicated
3. **what** — the offending edge, import or call, quoted
4. **remedy** — the concrete move that resolves it

Example of the intended shape:

```
forbidden_dependency  packages/features/payments/payments_application
  payments_application depends on shipments_application
  A feature may only reach another feature through its _api package.
  Replace the dependency with shipments_api and consume the port declared there.
```

`--format=json` emits the same four fields per violation.

Three exit codes, and the third one matters: **0** clean, **1** violations found, **64** the checker could not run — bad arguments, a missing root, an unreadable `rules.yaml`. A tool that exits 1 both for "the architecture is broken" and for "I could not read my own rules" teaches CI to treat the second as the first, and a rule file that fails to parse then reads as a clean workspace.

---

## 8. The rules that are not mechanical

Three constitutional rules resist a checker and stay a review responsibility. They are listed here so that nobody mistakes "arch_check is green" for "the architecture is intact".

- **Rule 1.2.6, cycle resolution.** `arch_check` detects a cycle, but it cannot tell you that the right fix is mutual `_api` dependencies rather than a new `shared` package. Creating `shared` makes the graph green and the architecture worse.
- **Rule 1.2.10, DTO/entity separation.** The checker can prove a DTO is not declared in `_api`. It cannot prove that a mapper in `_infrastructure` actually maps rather than passing a DTO-shaped entity through.
- **Rule 4 of §2.1, adapter scope.** Whether an adapter has quietly taken on a use case's job is a judgement about intent, not about imports.
- **§2.2.1, what belongs in `core_kernel`.** A checker can count the types in it. It cannot tell you that `PageOf` carries no domain meaning and `ShipmentSummary` does — and the failure mode is not a violation but a slow one: a `core_kernel` that has quietly become the `shared` package §2.1 forbids, one convenient type at a time.
- **Paging's ordering requirement.** `ShipmentGateway.manifestFor` promises its pages are served over a stable total order, and nothing can check that a server keeps the promise. It is the assumption every cursor rests on: without it a row that moves between two requests is served twice or never, which reaches a courier as the same door twice or a parcel that never appears.
- **The `_api` folder layout.** `arch_check` reads pubspecs and imports; it does not read paths, so nothing stops a port from being written into `values/`. The scaffolder produces the layout and its generator test holds that, which covers every package created from here on and no package created before. Where a file sits is a claim about what it is, and a driven port filed under `values/` is a wrong claim that compiles.
- **§2.3, driving-port width.** A checker can see that `app_dispatcher` does not register `RouteFollowing`. It cannot tell you that `resequence` and `recalculateOnDeviation` belong to different audiences in the first place — that is a reading of the product, and getting it wrong produces a graph that is green and a desk that answers a courier's question with the desk's coordinates.

---

## 9. Changing these rules

Rules change through a pull request that touches this document, `tooling/arch_check/rules.yaml` and a fixture under `tooling/arch_check/test/fixtures/` proving the new or changed rule fires. A rule with no fixture is a rule that will silently stop working.
