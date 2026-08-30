# CLAUDE.md — working rules for this repository

This file is the constitution. Read it in full at the start of every session, together with [`docs/DEPENDENCY_RULES.md`](docs/DEPENDENCY_RULES.md). The original task definition this repository is built from is [`docs/HEXAGONAL_MONOREPO_PROJECT_SPEC.md`](docs/HEXAGONAL_MONOREPO_PROJECT_SPEC.md); when this file and the spec disagree, the spec wins and this file gets corrected.

**What this repository is:** a reference implementation of hexagonal architecture (ports and adapters) in a 75-package Flutter monorepo. The sample product is **Peyk**, an enterprise courier and field-operations platform. The goal is not a shippable app — it is a compiling, test-passing skeleton in which every architectural rule is physically visible.

**Success criteria** (all must hold at every phase boundary):

1. `dart analyze` is clean across the workspace — zero errors, zero warnings, zero infos.
2. `dart run tooling/arch_check/bin/arch_check.dart` reports zero violations.
3. All written tests pass.
4. `dart run tooling/dep_graph/bin/dep_graph.dart` produces a graph with no cycles.
5. Every package has its own `pubspec.yaml` whose dependency list matches the constitution exactly.
6. `dart run melos run gen` followed by `git diff --exit-code` is clean — generated files are committed and current.

**Explicitly not required:** a real backend, finished visuals, complete business logic in every use case, or iOS/Android builds.

---

## 1. The dependency constitution

### 1.1 Package types and allowed dependencies

| Package type | May depend on |
|---|---|
| `core_kernel` | nothing (pure Dart, no third party) |
| `core_ports` | `core_kernel` |
| `core_navigation` | `core_kernel` |
| `core_testing` | `core_kernel`, `core_ports`, `core_navigation` |
| `<feature>_api` | `core_kernel`, `core_ports`, other features' `_api` packages only |
| `<feature>_application` | own `_api`, `core_kernel`, `core_ports`, other features' `_api` packages only |
| `<feature>_infrastructure` | own `_api`, `core_kernel`, `core_ports`, `platform/*` |
| `<feature>_presentation*` | own `_api`, other features' `_api`, `core_kernel`, `core_navigation`, `design_system` |
| `<feature>_testing` | own `_api`, `core_kernel`, `core_ports`, `core_testing`, other features' `_api` packages |
| `<feature>_core` (reduced split) | own `_api`, `core_kernel`, `core_ports`, `platform/*`, other features' `_api` |
| `platform/*` | `core_kernel`, `core_ports`, the `flutter` SDK |
| `design_tokens` | nothing (except the `flutter` SDK) |
| `design_system` | `design_tokens`, `core_kernel` |
| `tooling/*` | no product package |
| `apps/*` | anything |

A dependency that is not in this table is a violation, not an exception. If you believe you need one, stop and report it rather than adding it — those moments are where the architecture teaches the most.

**Two platform packages never depend on each other.** They do need each other's capabilities — `location_service`, `media_capture` and `push_messaging` all need a permission that `device_permissions` grants — and the resolution is the one used everywhere else: depend on the *port* in `core_ports`, take it through the constructor, and let an app's composition root supply the adapter.

### 1.1.1 Where a contract is declared

`core_ports` and `platform/*` both declare interfaces. The test for which is which is what the interface speaks in:

| | `core_ports` | `platform/<name>` |
|---|---|---|
| Speaks in | the product's words | a technology's words |
| Example | `SecureStore`, `Clock`, `NetworkStatus` | `HttpTransport`, `LocationSource`, `MediaCapture` |
| Bar for entry | more than one feature needs it, none owns it | one technology answers it, adapter in the same package |
| Fake lives in | `core_testing` | the same package as the contract |

Nothing in the product asks for "an HTTP request" or "a GPS fix". A feature asks for a shipment or a delivery proof, through a port in its own `_api`, and its `_infrastructure` answers that *using* a technology contract. The table above already enforces the consequence: `_application` may not depend on `platform/*`, so a use case can never see an `HttpRequest` and can never end up owning a retry policy.

### 1.2 Invariants

1. **Features touch each other only through `_api`.** A feature's `_application`, `_infrastructure` or `_presentation` package is never imported by another feature.
2. **`_application` and `_infrastructure` never see each other.** Only an app's composition root joins them.
3. **`_api` and `_application` are pure Dart.** No `flutter` SDK dependency in their pubspecs. This is the foundation of test speed and it is not negotiable.
4. **Ports are declared in `_api`, implementations live outside it.** Not one line of implementation belongs in an `_api` package.
5. **Every package exposes its public surface through a single barrel** at `lib/<package_name>.dart`. Everything else lives under `lib/src/`. Importing `package:x/src/...` from another package is forbidden.
6. **The dependency graph has no cycles.** When two features need each other, the answer is mutual `_api` dependencies — never a new `shared` or `common` package.
7. **Service locators exist only in the app layer.** No `GetIt` or global access inside packages; dependencies arrive through constructors.
8. **`DateTime.now()`, `Random()` and `Uuid()` are never called directly.** They come from the `Clock`, `RandomSource` and `IdGenerator` ports in `core_ports`. This is what makes tests deterministic.
9. **No exception crosses a port boundary.** Every port method returns `Result<Success, Failure>`. Failure types are `sealed class`es declared in the owning `_api` package.
10. **DTOs never leak into the domain, entities never leak out.** Translation happens in mappers inside `_infrastructure`.

---

## 2. Forbidden — doing any of these breaks the spec

1. Adding a `flutter` dependency to an `_api` or `_application` package
2. Importing another feature's `_application`, `_infrastructure` or `_presentation` package
3. Wiring `_application` directly to `_infrastructure`
4. Resolving a mutual need between two features by creating a `shared` or `common` package
5. Using `GetIt` or a global singleton inside a package
6. Calling `DateTime.now()` or `Random()` directly
7. Throwing an exception across a port boundary
8. Importing from another package's `src/` directory
9. Exporting `src/` internals from a barrel file
10. Hand-editing a generated file, or adding generated files to `.gitignore`
11. Using code generation inside `core_kernel`
12. Running `json_serializable` in, or declaring a DTO in, an `_api` package
13. Using annotation-based DI (`injectable`) inside a package
14. Leaving unneeded builders enabled in a package's `build.yaml`
15. Adding a type to `core_kernel` that is not strictly needed
16. Leaving a tooling package untested
17. Collapsing a whole phase into a single commit
18. Pushing directly to `main`, or rewriting its history
19. Putting generated files in a separate commit from their sources
20. Committing a change that does not pass the tests and `arch_check`

---

## 3. Code conventions

- Ports are declared as `abstract interface class`.
- Failure and state types are `sealed class`.
- `Result<S, F>` lives in `core_kernel` with `fold`, `map` and `flatMap` helpers.
- **A port method returns `Result` when the operation can fail, and a plain value when it cannot.** Invariant 1.2.9 forbids an exception crossing a port boundary; it does not require a failure branch that can never be taken. `Clock.now()`, `IdGenerator.newId()` and `RandomSource.nextInt()` return plain values — they have no failure mode, and wrapping them would put an unreachable `Failed` case at every call site. Everything that touches I/O, a device capability or a remote system returns `Result` with a `sealed` failure type declared in the package that owns the port. The prohibition on throwing still applies to every port without exception.
- Value objects use a private constructor plus a validating factory that returns a `Result`.
- Entities are immutable, carry behaviour, and evolve through `copyWith`.
- **Inside a package, import by relative path; across packages, import the barrel.** This inverts what very_good_analysis prefers, and the reason is rule 1.2.5. While a package may legitimately write `package:<self>/src/...`, every occurrence of `package:*/src/` has to be checked against which package the file lives in before a violation can be told from a normal import. With relative imports inside a package, that pattern means one thing only — someone reached across a boundary — so the rule becomes a grep and `arch_check`'s deep-import check becomes exact instead of context-sensitive.
- File names are `snake_case`; one public type per file.
- Every package has a short `README.md`: what it is for, what it may depend on, and what must never live in it.
- Comments and documentation inside code are written in English.

---

## 4. Code generation

### 4.1 Tool placement

| Tool | Runs in | Produces |
|---|---|---|
| `freezed` | `<feature>_api` (entities, value objects, sealed state and failure types) | immutable classes, `copyWith`, unions |
| `json_serializable` | `<feature>_infrastructure` and `platform/*` — DTOs only | JSON conversion |
| `drift_dev` | `platform/storage_drift` and `_infrastructure` packages that persist | tables, DAOs, migration scaffolding |
| `injectable_generator` | `apps/*` only | DI registration |
| `go_router_builder` | `<feature>_presentation*` | type-safe routes |
| `flutter gen-l10n` | `apps/*` and `design_system` | localization classes |

### 4.2 Rules

1. **No code generation in `core_kernel`.** It is the innermost ring, so regeneration cost there spreads across the entire repository. `Result`, the `Failure` base and `ValueObject` are hand-written.
2. **DTOs are never declared in `_api`.** `json_serializable` runs only in `_infrastructure` and `platform/*`. Break this and serialization concerns leak into the domain.
3. **`freezed` does not replace domain validation.** Validity checks stay in hand-written factories; `freezed` only produces the data-carrying skeleton.
4. **`injectable` is app-layer only.** Inside packages, dependencies arrive through constructors.
5. **Generated files are committed.** They never enter `.gitignore`.
6. **Generated files are never hand-edited.** If an output is wrong, fix the source or the `build.yaml`.

### 4.3 Why generated files are committed

Three reasons, in increasing order of importance. *CI time*: without them, every CI run starts by generating the whole workspace. *Reviewability*: the diff a source change produces is visible in the pull request. *Correctness of affected-test selection*: test selection is derived from `git diff`; if generated files are not in the repository, files produced later in the workspace are invisible to the diff and the affected-package set comes out wrong.

The cost is diff noise, mitigated by the `linguist-generated=true` entries in `.gitattributes`.

### 4.4 Running build_runner in a monorepo

Running codegen across the whole workspace is not acceptable. Use the melos scripts:

| Script | Scope | When |
|---|---|---|
| `dart run melos run gen` | changed packages and their dependents | everyday work, before every commit |
| `dart run melos run gen:all` | the entire workspace | nightly, and after a large refactor |
| `dart run melos run l10n` | every package with an `l10n.yaml` | after touching an `.arb` file |
| `dart run melos run gen:check` | `gen` + `l10n` + `git diff --exit-code` | CI staleness gate |
| `dart run melos run gen:watch` | one package | while working on that package |

`flutter gen-l10n` is the one generator in §4.1 that build_runner does not drive, so it does not travel with `gen`. It has its own script, and `gen:check` runs both — a stale `.arb` has to fail the same gate a stale `.g.dart` does. Its output is written into `lib/src/` and committed, not left in the synthetic package Flutter defaults to: a generated file that exists only inside `.dart_tool` cannot be reviewed in a pull request, and cannot be seen by the affected-test selection derived from `git diff` (§4.3).

Every package gets its own `build.yaml` and **enables only the builders it needs**; by default build_runner scans every builder in every package, which is significant waste across 75 packages. Narrow the builders' globs with `generate_for` as well.

---

## 5. Commit discipline

**Frequency.** Commit at every meaningful unit of work. Collapsing a phase into one commit is forbidden. Practical measure: one commit when a package is complete, when a rule is added to `arch_check`, when a contract kit is written. A phase producing 15–40 commits is normal.

**Format.** Conventional Commits, with the package or area as scope:

```
<type>(<scope>): <summary>

<body: why this change was made, which architectural decision it reflects>
```

Types: `feat`, `fix`, `refactor`, `test`, `docs`, `build`, `ci`, `chore`, `perf`.

The body matters more here than in a normal repository. This is a reference repository, so the *why* is as valuable as the code. Every commit that makes an architectural decision gets a body.

**Before every commit**, these must be clean:

```bash
dart run melos run gen
dart analyze
dart run tooling/arch_check/bin/arch_check.dart
dart run tooling/dep_graph/bin/dep_graph.dart --check
```

Plus the tests of the affected packages — `dart run melos run test:affected` from phase 8 on. The fourth line is there for the same reason the first is: `docs/dependency-graph.md` is generated and committed, so a commit that adds a package or moves an edge carries the regenerated graph with it. Before `arch_check` exists (phases 0–2), verify the rules by hand and state in the commit body which rule you verified.

**Never:** force-push, rebase-rewrite `main`, split generated files from their sources into a separate commit, or commit for the sake of committing.

---

## 6. Branch and phase workflow

`main` is protected; direct pushes are rejected. Each phase gets its own branch: `phase/00-foundation`, `phase/01-core`, `phase/02-platform`, `phase/03-tooling`, `phase/04-reference-features`, `phase/05-cross-cutting`, `phase/06-light-features`, `phase/07-composition-roots`, `phase/08-ci-and-docs`. Do not open sub-branches inside a phase; move in small commits on the one branch.

At the end of a phase:

```bash
git push -u origin phase/NN-name
gh pr create --title "Phase N: ..." --body-file <summary>
gh pr merge --merge          # never squash: the in-phase history is the lesson
git checkout main && git pull
git tag -a phase-NN -m "Phase N complete: ..."
git push origin phase-NN
```

The pull request description states: the phase's scope, the number and names of packages added, which architectural rule became visible in this phase, the `arch_check` output, the test count, and known gaps.

---

## 7. Adding a new package

Use the scaffolder (`tooling/scaffold`, from phase 3):

```bash
dart run tooling/scaffold/bin/scaffold.dart new-feature --name billing --split full
dart run tooling/scaffold/bin/scaffold.dart new-feature --name faq --split reduced
dart run tooling/scaffold/bin/scaffold.dart new-feature --name shipments \
  --split full --with-testing --presentation courier,dispatcher
```

`--with-testing` adds the `_testing` package; create it only when another package's tests will consume its fakes. `--presentation a,b` gives the feature one presentation package per app. `--codegen` writes a `build.yaml` and the matching dev dependencies for the roles that generate — off by default, because a package with no generated files is supposed to have neither (§4.2 and point 6 below). `--dry-run` lists what would be written; `--force` overwrites, and without it a re-run leaves existing files alone, which is what makes it safe to re-run on a feature that already exists.

Doing it by hand — or checking the scaffolder's output — means verifying all of the following:

1. Directory sits under `packages/<group>/<feature>/<package_name>/`, and the package name equals the directory name.
2. `pubspec.yaml` has `resolution: workspace`, and its dependency list matches the table in §1.1 exactly — nothing more.
3. The root `pubspec.yaml` `workspace:` list includes the new path.
4. A barrel exists at `lib/<package_name>.dart`, and it is the only file directly under `lib/`.
5. Implementation lives under `lib/src/`; the barrel exports only the public surface.
6. If the package uses code generation, `build.yaml` enables only the builders it needs and disables the rest explicitly. A package with no generated files has no `build_runner` dependency and no `build.yaml`, so no builder ever runs there — that is the cheapest configuration, not a missing one.
7. A `README.md` states the package's role, its allowed dependencies, and what must never live in it.
8. A `test/` directory exists, even if it starts with a single smoke test.
9. `dart run tooling/arch_check/bin/arch_check.dart` is clean afterwards.

The scaffolder's own acceptance test is exactly item 9: it generates every shape of feature into a throwaway workspace and runs `arch_check` over the result. A change to the constitution that the scaffolder does not follow fails there before anyone notices it in a real feature.

**Choosing a split.** Full split (`_api`, `_application`, `_infrastructure`, `_presentation`, `_testing`) is for features with real business rules, more than one outbound adapter, or offline behaviour. Reduced split (`_api`, `_core`, `_presentation`) is the starting point for narrow features; `_api` is separate in every case. A `_testing` package is created only when its fakes are consumed by another package.

---

## 8. Common mistakes

| Mistake | What to do instead |
|---|---|
| Putting a DTO in `_api` because "it's just a data class" | DTOs belong in `_infrastructure`. `_api` holds entities and value objects only. |
| Adding `flutter` to `_application` for `ChangeNotifier` or `debugPrint` | Use `core_ports/Logger`; state types stay pure Dart. |
| Reaching for a `shared` package when two features need each other | Mutual `_api` dependencies. Contract packages depend on no implementation, so the graph stays acyclic. |
| Calling `DateTime.now()` in a use case | Inject `Clock`. A test that uses the real clock is a test that will flake. |
| Letting an adapter throw | Catch at the adapter boundary and map to a `sealed` `Failure`; return `Result`. |
| Importing `package:other_feature/src/foo.dart` for a type that is not exported | If the type must be shared it belongs in the barrel; if it must not, you are reaching across a boundary. |
| Hand-fixing a wrong `*.freezed.dart` | Fix the source or `build.yaml`, then regenerate. |
| Enabling every builder in a new package's `build.yaml` | Enable what the package type needs, disable the rest explicitly. |
| Committing source without its regenerated output | They travel in the same commit; otherwise affected-test selection lies. |
| Chasing `depend_on_referenced_packages` errors the IDE reports but `melos run analyze` does not | The editor is running an SDK older than Dart 3.6. See below — the command line is the source of truth. |

---

### When the editor disagrees with the command line

If the editor reports `depend_on_referenced_packages` on imports that `melos run analyze` accepts, it is running a Dart SDK older than **3.6**, which is where pub workspaces landed. Such an SDK has no concept of `resolution: workspace` and cannot follow `.dart_tool/pub/workspace_ref.json`, so it fails to resolve every `package:` URI in the workspace.

Two symptoms identify it, and both look like something else:

- `depend_on_referenced_packages` on nearly every import, **including a file importing its own package**. That is the giveaway: the lint never fires on a package's own name, so seeing it means package resolution is dead rather than a dependency being genuinely absent.
- `unused_import` on an import that exists only to resolve a doc reference, because the unresolvable package makes the `[Type]` reference fail too.

Confirm it by finding the language server the editor actually launched and asking its version:

```bash
ps -eo command | grep "language-server" | grep -v grep
```

The usual cause is PATH: an editor launched from the Dock does not inherit the shell's PATH, so it resolves `dart` from the system default rather than from the Flutter SDK. Pin it instead of relying on PATH — in VS Code, `dart.sdkPath` set to `<flutter>/bin/cache/dart-sdk`.

`dart analyze` from the command line is the source of truth, and `melos run analyze` is what the hooks and CI run. When the two disagree, check the editor's SDK before changing any code.

---

## 9. Session checklist

At the **start** of a session: read this file and `docs/DEPENDENCY_RULES.md`, check out the phase branch, and confirm which phase you are in. Do not start the next phase before the current one is tagged.

Before **each commit**: `dart run melos run gen`, `dart analyze`, `arch_check`, affected tests.

At the **end** of a phase: verify the acceptance criteria in the spec, push, open the pull request, merge without squashing, tag `phase-NN`, and push the tag.

**When a rule feels like it needs bending: stop and report it instead of bending it.**

---

## 10. Where the work stands

This section is the handoff between sessions. It is rewritten at every phase boundary and it is the only part of this file that is expected to go stale — everything above is the constitution. Read it after section 9, then check it against `git log` before trusting it.

**Branch:** `feat/push-deep-links`. **Last tag:** `phase-08`. The eight phases the specification defines are complete, merged and tagged; `main` is protected. What follows the spec is ordinary product work under the same constitution, and this is the first of it. **Working tree:** clean; `arch_check` clean across 75 packages; `dart analyze --fatal-infos --fatal-warnings .` clean across the workspace; `melos run test` green (1,895 cases in 172 test files); `melos run gen:check` and `graph:check` clean.

### Phase 8 is complete, merged and tagged

Two tooling packages added — `dep_graph` and `test_runner` — the CI files written, and the four documents the specification asks for by name.

| Added | What it is for | What it demonstrates |
|---|---|---|
| `tooling/dep_graph` | renders the graph into `docs/dependency-graph.md`, fails on a cycle | success criterion 4, checked rather than described; four views, because *which* scope you draw is the whole design |
| `tooling/test_runner` | affected selection, runner choice, bundling, hash-skip, bucketing, JUnit | how a 100,000-test suite stays runnable: nobody ever runs all of it for one change |
| `.github/workflows/*`, `codemagic.yaml`, `fastlane/` | the pipeline | every gate placed by one rule — the earliest place that can afford it |
| `docs/ARCHITECTURE.md`, `TESTING.md`, `CI_CD.md`, `dependency-graph.md` | the explanation half | the seven scenarios, the pyramid, and where each gate lives |

### Phase 8's first item — settled: driving ports are per audience

The debt phase 7 deferred is closed. The note is **[`docs/research/facade-port-coupling.md`](docs/research/facade-port-coupling.md)**, now resolved; the rule it produced is **[`docs/DEPENDENCY_RULES.md` §2.3](docs/DEPENDENCY_RULES.md)** with its non-mechanical half in §8; the narrative lives in `docs/ARCHITECTURE.md` under scenario 5.

`RoutingFacade` became `RoutePlanning` / `RouteSupervision` / `RouteFollowing`, and `DeliveryFacade` became `DeliveryExecution` / `DeliverySettlement` / `DeliveryHistory`. `app_dispatcher` composes only what a desk can answer and no longer depends on `location_service`; its container test asserts `RouteFollowing` and `DeliveryExecution` are *not registered*.

Three things worth not rediscovering:

- **Phase 7's own account of the seam was wrong.** It said no dispatcher screen called the courier-only use cases. `RouteScreen` is mounted at `routing.courierRoute`, its `initState` calls `load`, and `load` called `recalculateOnDeviation`. The desk's GPS stayed out of the answer only because the desk's *local* route cache is empty — an accident of adapter choice. "Nothing calls it" is a claim about every call site forever; do not accept it as a guarantee again.
- **Segregating an interface is not segregating a composition.** `IdentityCoordinator` implements three ports from one constructor; that limits what a caller may ask and not what an app must supply. Routing and delivery needed one coordinator per port, plus a `RouteChannel` / `DeliveryChannel` for the change stream the split would otherwise have split too.
- **Capability absence and intent absence want opposite answers.** A driven port a device cannot answer gets an adapter that declines (`DeskAlertChannel`). A driving operation an audience never performs is absent from the interface it holds. §2.3 is that table.

### Decisions made in phase 8 — do not re-litigate

- **`dep_graph` reads `arch_check`'s `rules.yaml` as data, and does not import `arch_check`.** §2 gives a tooling package an empty allow-list, so the workspace walk is a second copy on purpose. The *type decision* stays single-sourced: a diagram that classified a package differently from the checker would be a diagram that lies.
- **Mermaid never draws the whole workspace.** Seventy-five nodes and four hundred edges render as a wall. Mermaid gets three views that carry an argument; the complete graph goes out as DOT, which has a layout engine.
- **Nothing generated is time-stamped.** A generated file that changed one byte per run would fail the staleness gate on every commit and be ignored within a week.
- **`test_runner` enumerates the workspace from the root pubspec's `workspace:` list**, not by walking directories. That list is what pub resolves against.
- **A failed git diff runs everything.** A selective run built on a failed diff silently covers nothing, and a green CI on an unfetched base is the failure nobody notices.
- **Affected selection walks `dev_dependencies` too.** A broken contract kit breaks its consumers' suites and nobody's build.
- **The hash-skip cache is never shared between machines.** It is a claim that *this machine* saw a package pass. CI passes `--no-cache`.
- **Bundling is a flag, not the default.** A library-level `@Tags` belongs to the file that carries it and a bundle is a different file, so any run that filters by tag stays unbundled. The merge queue bundles; the pull request does not.
- **JUnit is one test case per package.** The runner reads exit codes; parsing two machine reporters into per-test cases would make it a third, worse test framework.
- **A Fastlane lane never builds.** Codemagic builds and signs; a lane moves an artefact that already exists, so a failed upload stays distinguishable from a failed compile.

### The one thing phase 8 states rather than fixes

`codemagic.yaml` and `fastlane/Fastfile` are real and consistent and **cannot run in this repository as it stands**. There is no `apps/*/android/`, no `apps/*/ios/` and no `apps/*/config/<flavour>.json`, because the specification explicitly does not require iOS or Android builds. Both files say so at the top, and `docs/CI_CD.md` §7 repeats it. `flutter create --platforms=android,ios .` inside an app is the step that closes it.

### What the merge exposed, and what is left

**The first real `pr` run was red, and PR #13 was merged over it.** That is the argument for the protection rule below, not against it.

The golden step ran `flutter test --tags golden` in every package with a `test/` directory. `package:test` answers *No tests ran* with exit **79**, and no test in this workspace carries the `golden` tag, so an empty selection came back as seventy-five failures — a gate whose only possible answer was red. Fixed on `fix/pr-golden-selection`: the step greps for the tag, runs only where it finds it, and says so and stops when it finds it nowhere. `test_runner` stopped reading 79 as a failure in the same commit, because the latent version of the same bug is a package that carries nothing but goldens, whose whole suite the `pr` preset excludes.

The general rule, now in `docs/CI_CD.md` §3 and `docs/TESTING.md`: **a gate written before the thing it gates has to have a defined answer for the empty case**, and "red" is not it.

### After the spec: navigation and the first three flows

The workspace had seventy-five packages, twenty-three routes and **zero navigation calls** — every screen an island reachable only by URL. The note is [`docs/research/navigation-and-flows.md`](docs/research/navigation-and-flows.md); the rule it produced is [`DEPENDENCY_RULES.md` §2.4](docs/DEPENDENCY_RULES.md), checked by `arch_check`'s new `I8` and `A6`; the narrative is in `docs/ARCHITECTURE.md` under scenario 7.

**The decision: a screen reports an outcome, the app decides the destination.** The two alternatives were researched and rejected for reasons specific to this workspace, not taste. `context.goNamed` inside a screen cannot work here — route names live in presentation packages and a feature may not import another feature's presentation package, so a cross-feature destination could only be an unchecked string. A navigation interface in `core_navigation` would have to name every destination, which is §2.1's forbidden `shared` package wearing a router's clothes. Google's Compose-era multi-module guidance and Now in Android reach the same answer for the same reason.

`ProofCaptureScreen.onCaptureSignature` was already this shape — the app supplies a capability the package may not depend on. A flow step is the same shape applied to a destination.

Three things worth not rediscovering:

- **Entry and continuation are different problems.** A notification tap cannot invoke a callback, so arrival stays a URL (`RouteDefinition.path` + `redirectFor`) and only continuation became a callback. Confusing the two is what makes people reach for a router in a package.
- **The flow forks where the domain forks, and the first version got it wrong.** `onSettled` fires for a visit that ended *without* a hand-over too; the first `CourierFlow.afterProof` sent every settled attempt to collection, which would have asked a courier to collect for a parcel they took away. `AttemptOutcome` is sealed, so the fix is a switch the compiler checks.
- **`CourierFlow` is a pure function to a `(route, parameters)` record, and that is the point.** Its test asserts every route name it can produce is one the app actually mounted. Scattered `context.goNamed` calls could never be checked that way, because no presentation package knows what an app mounted.

Also closed, because both were gaps the code had already documented: `IdentityFacade.signOut` had no call site in the workspace and `sessionChanges` had no subscriber (so the guard only ran on navigation, and an ended session left somebody on the screen); and `SyncFacade.drain` named its caller in its own doc comment — "a connectivity change, a foreground transition, a timer in the composition root" — while nothing was that caller. `SessionRefresh` and `SyncOrchestrator` are those two, one copy per app.

`GoRouterRefreshStream` was removed from go_router after version 17. `SessionRefresh` replaces it in fifteen lines and deliberately throws the session value away: the guard reads `SessionReader.current` when it runs.

### `main` is protected as of 2026-08-28

`verify` is a required status check, branches must be up to date before merging, administrators are included, and force pushes and deletions are blocked. §8 of `docs/CI_CD.md` carries the table and the reasoning.

**The merge queue's ten buckets are not required checks**, and that is a correction to what §8 used to claim. `verify` runs on `pull_request` and the buckets run on `merge_group`; GitHub evaluates one required-checks list against the merge group, so a required `verify` would never arrive there and the queue would hold every pull request forever. The queue is off, `main.yml` runs through its `push: main` fallback, and the buckets report after a merge rather than gating it. Turn the queue on — and give `pr.yml` a `merge_group` trigger in the same commit — the day two branches are in flight at once.

### Start here in the next session

`main` is protected and green, and nothing from the specification is outstanding — its acceptance criteria all hold and every phase is tagged `phase-00` … `phase-08`. PR #16 (`ccee0a6`) closed the navigation work; the shell work below sits on `refactor/drop-navigation-port`.

Three items, in the order they should be taken. All three are closed; what follows them is in the last section.

#### 0. `core_navigation`'s `Navigation` port — deleted, done

`Navigation` (`goTo`, `replaceWith`, `back`) was candidate (b) of the navigation note written in phase 1 and never used: no package outside `core_navigation` and `core_testing` mentioned it, while its own doc comment taught the design §2.4 rejects. It is gone, with `RecordingNavigation`, `NavigationRecord` and their tests, and `core_testing` lost the `core_navigation` dependency it held only for them — the constitution permits that edge, but an unused dependency is still removed.

`RouteLocation` stays. Describing a destination and deciding to go there are different jobs, and the shell work below wants the first.

The rejected alternative and its reason are recorded in `docs/research/navigation-and-flows.md` §8: an app-side abstraction over the router is a layer with one implementation and no second candidate. It comes back the day a third app routes with something other than `go_router`.

#### 1. The bottom navigation bar — built, and one prediction it falsified

`app_courier` has four tabs. The note is [`docs/research/tabbed-shell.md`](docs/research/tabbed-shell.md); the narrative is in `docs/ARCHITECTURE.md` under scenario 7; nothing in `DEPENDENCY_RULES.md` changed, because this is §2.4 applied one level down and §2.3 applied one level up rather than a new rule.

`PeykNavigationBar` and `PeykIcon` are in `design_system`; `courierTabs`, `CourierShell` and `PeykRouter`'s `branches`/`shell` parameters are in `app_courier`. The other two apps still build a flat router, which is what those parameters defaulting to nothing is for.

Three things worth not rediscovering.

- **`RouteDefinition` did not need a branch concept, and the handoff was wrong to expect one.** The only fact about a tab that belongs to a feature is that its root opens with no argument, and `path` already says it: `/stops` can be a tab, `/stops/:shipmentId/proof` cannot. The test reads `path`. Before adding a field to a contract package, check whether the fact is derivable from a field already there — a contract with two ways to say the same thing has two ways to disagree.
- **The sign-out test found a defect that had nothing to do with tabs.** The branch stacks were fine; the *guard's memory* was not. `redirectFor` attaches `?from=` to every refusal so a followed link survives signing in, and an ended session is refused wherever its owner was — so signing back in returned there. On a shared handset that is the next courier landing on the previous one's parcel. Interception and ejection are indistinguishable to a pure `redirectFor`; `SessionRefresh` is the only place that sees the transition, and it now clears the location before the guard reads it. Fixed in all three apps.
- **A test that passes without the fix is not a test.** The first draft of the second session-end test asserted the app landed at home after re-signing in — and the harness's home was the screen the test happened to be on, so it passed either way. Going somewhere else first is what gave it teeth. Both session-end tests were re-run with the fix removed.

Open, and deliberately not in this change: `app_dispatcher` has no shell (a desk wants a sidebar, a different component with the same split), and the inbox tab has no unread badge (`PeykBadge` exists; where the subscription lives is its own decision).

#### 2. Deep-link entry from a push payload — done

`PushEntry` and `CourierEntryPoints` in `app_courier` are the caller §4.1 of the navigation note reserved a row for. The note is [`docs/research/push-entry.md`](docs/research/push-entry.md); nothing in `DEPENDENCY_RULES.md` changed, because entry-stays-a-URL was already the rule.

The platform contract grew the distinction it was missing: `messages()` is a push *arriving*, `openings()` is somebody *pressing* it, and `launchMessage()` is the press that started the app from nothing. Acting on the first would take a courier off a half-drawn signature for a message they have not read.

Three things worth not rediscovering.

- **`launchMessage()` is consumed by reading, and the fake consumes it too.** The provider hands it over once, so an app that read it twice would navigate to the same push again on its next resume. A fake that kept answering would let a test pass against behaviour the device will not repeat.
- **It answers `null`, not a `Result`.** Web and desktop do not implement `getInitialMessage`; a launch this app cannot read about and a launch nobody caused mean the same thing to a caller. §3's rule — `Result` when the caller can act on the failure — decided it.
- **`PushMessage` carries `shipmentId` and `threadId` now.** The DTO decoded them and the mapper dropped them, so the app would have read `data['thread_id']` and become a second place a server rename breaks.

The test that pays for the design: a notification pressed while signed out lands on `/sign-in?from=/threads/shipment%3ASHP-1` and arrives at the thread once there is a session. Every arrow in that chain already existed and had nothing entering from outside the app.

Open, and deliberately so: the scanned barcode and the pasted URL produce no locations yet (both need no new mechanism — `shipments.courier.scan` is mounted at `/stops/scan`), a push that merely arrives shows nothing in-app, and `app_dispatcher` has no `PushEntry` because a desk does not run on notification presses.

#### What is worth taking next

Nothing here is owed. These are the threads the last three notes left hanging, in the order they would pay off.

1. **`app_dispatcher` has no shell.** A desk wants a persistent sidebar, not a bottom bar: the same split as `courierTabs` / `PeykNavigationBar` / `CourierShell`, with a different component and a different tab set. It is the cheapest way to find out whether the shell split generalises or whether it was shaped by one app.
2. **An unread badge on the inbox tab.** `PeykBadge` exists and `PeykNavigationDestination` does not carry a count. The real question is not the widget: it is where the subscription lives, because a bar that reads a facade would be a component that knows a feature.
3. **A push that merely arrives shows nothing.** `messages()` is deliberately not acted on, and an in-app banner is a design decision with no component behind it.
4. **The first golden or integration test.** The tags, presets, exclusions and CI steps are all in place and nothing carries the tags, so two gates have never run against a real selection. The shell is the obvious first golden.

The two gaps the repository states rather than fixes are unchanged and deliberate: `codemagic.yaml` and `fastlane/Fastfile` cannot run without `apps/*/android/`, `apps/*/ios/` and `apps/*/config/<flavour>.json` (the specification excludes native builds), and no test carries the `golden` or `integration` tag yet — the tags, presets, exclusions and CI steps are the mechanism, and the images arrive with the screens that need them.

### Verification, before every commit

```bash
dart run melos run gen         # only where build_runner is a dev dependency
dart run melos run l10n        # only where an l10n.yaml exists
dart analyze --fatal-infos --fatal-warnings .
dart run melos run arch:check
dart run melos run graph:check # the graph is generated and committed too
dart run melos run test:affected
```

`melos run test` still runs the whole workspace, and `test:affected` is what the hook and CI run. Prefer the second while working and the first before a phase pull request.

The pre-commit hook runs format, analyze **on staged files only**, and `arch_check` over the whole workspace. Analyze on staged files is the gap, and phase 7 hit it: a half-migrated `settings_presentation` was staged while its fix was not, and the hook refused the commit for the right reason but with a confusing message. Run `dart analyze` over the workspace before a phase PR.

`melos run gen` is also a staleness gate in practice. Phase 7 found `app_harness`'s generated container drifting because one `@InjectableInit` was missing `preferRelativeImports` — regeneration produced absolute self-imports, which rule S3 reads as reaching across a boundary.

**One flake seen in phase 6, not reproduced since:** `storage_drift` failed once under `melos run test` and passed on every re-run. If it recurs, suspect concurrent access to the temporary SQLite files rather than the code.
