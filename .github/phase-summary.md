# Phase 8 — test runner, CI/CD and the documentation

The last phase. Two tooling packages, the whole pipeline, and the four documents the specification asks for by name — plus the architectural debt phase 7 deferred, researched and settled before anything else was written.

## Scope

| | |
|---|---|
| Packages added | 2 — `tooling/dep_graph`, `tooling/test_runner` |
| Workspace total | **75 packages** |
| Commits | 8 |
| Tests | **1,530** across 161 files, of which **61** are new (20 in `dep_graph`, 41 in `test_runner`) |
| `arch_check` | clean — 75 packages, no violations |
| `melos run test` | SUCCESS |
| `gen:check`, `graph:check` | clean |

Two features changed shape: `routing` and `delivery`. That was not a phase-8 goal; it was the answer to the question phase 7 left open, and it is the most useful thing in this branch.

## What became visible in this phase

### A runtime guarantee, believed for three days, that was already false

Phase 7 recorded a seam: `app_dispatcher` binds a `LocationStreamPort` over the desk's own GPS and an `HttpGeoFence` that asks whether the desk is at a consignee's door. It called them safe *because no dispatcher screen calls the use cases behind them*.

That was wrong, and finding out how wrong is the phase's best lesson. `app_dispatcher` mounts `RouteScreen` at `routing.courierRoute`; `RouteScreen.initState` calls `RouteController.load`; `load` called `recalculateOnDeviation` — a command that reads the calling device's position and may replace the plan. The desk's GPS stayed out of the answer for an entirely unrelated reason: `RecalculateOnDeviation` reads the route cache first, and a desk's *local* cache is normally empty. That is an accident of adapter choice, and it disappears the day a desk gets the remote route cache it obviously wants.

**"Nothing calls it" is a claim about every call site in the workspace, present and future.** It is not a guarantee, and this repository's entire claim is that its guarantees are compile-time.

### The literature had already answered it, twice

The instruction that opened the research note was: find what the literature says *first*, then integrate. It said:

- **ISP in its original form** (Martin, the Xerox `Job` class) — a fat class made every client depend on methods it did not use, and the cost was paid in build and deployment.
- **CRP, the Common Reuse Principle** (*Clean Architecture* ch. 13) — the package-level counterpart, and the one that actually governs a 75-package workspace: *do not force a component's users to depend on things they do not need.* The harm here was transitive and visible in a `pubspec.yaml` as `location_service`.
- **Fowler on role versus header interfaces** — `RoutingFacade` was a textbook header interface, and its own doc comment admitted it: *"It is not called `RoutingFacadeImpl`."*
- **Cockburn** — a port is "the purpose of the conversation". His Figure 2 shows four clients driving one port, which had to be taken seriously as counter-evidence; it varies the *technology*, and the pattern's own canonical port list includes a separate **administration** port for a different actor.
- **Graça's "a port is a consumer agnostic entry point"** — resolved rather than dismissed: consumer-agnostic means *technology*-agnostic. Two audiences that differ in how they connect share a port; two audiences that differ in what they may or physically can do are two conversations.

### Splitting an interface is not splitting a composition

The obvious fix — role interfaces — was right and insufficient. `IdentityCoordinator` already implements three ports from one constructor, which segregates what a caller may *ask* and not what a composition root must *supply*. An app that still had to build an object whose constructor demanded `RecalculateOnDeviation` would still have needed a GPS.

So the implementations split too: one coordinator per port, and a `RouteChannel` / `DeliveryChannel` for the change stream — one fact that three interfaces report, which would otherwise have been split along with them.

| routing | operations | composed by |
|---|---|---|
| `RoutePlanning` | `planRoute`, `currentPlan`, `changes` | both |
| `RouteSupervision` | `resequence` | the desk |
| `RouteFollowing` | `nextStop`, `recalculateOnDeviation` | the vehicle |

| delivery | operations | composed by |
|---|---|---|
| `DeliveryExecution` | `startAttempt` | the courier |
| `DeliverySettlement` | `completeWithProof`, `failWithReason` | both |
| `DeliveryHistory` | `attemptsFor`, `changes` | both |

`CurrentPlan` is the query that was missing — the reason a screen was opening on a command. Command-query separation was the rule being broken, and ignoring it is what produced the defect.

### The rule that came out of it

New **§2.3 of `docs/DEPENDENCY_RULES.md`**, with its non-mechanical half listed in §8:

| | Absence of *capability* | Absence of *intent* |
|---|---|---|
| Which side | a driven port | a driving port |
| Example | a desk has no push client | a desk never stands at a consignee's door |
| The right answer | an adapter that declines (`DeskAlertChannel` → `AlertsRefused`) | the operation is not on the interface that audience holds |
| Why | the domain still *asks*, and "cannot" is a real answer | nobody asks, so a refusal is unreachable code standing in for a compile-time fact |

### Which scope you draw is the whole design of a graph tool

`dep_graph` renders four views, and the choice of scope is the decision. Seventy-five nodes and four hundred edges in Mermaid render as a wall; a diagram nobody can read is a diagram nobody checks against the code. So Mermaid gets three views that each carry an argument — the type-level graph you hold against §2, the payments/shipments pair that shows a mutual need with no cycle, and one full-split feature — and the complete graph goes out as DOT, which has a layout engine.

It reads `arch_check`'s `rules.yaml` as **data at a path** rather than importing `arch_check`, because §2 gives a tooling package an empty allow-list. The workspace walk is duplicated on purpose; the decision about a package's *type* is not, because a diagram that classified a package differently from the checker would be a diagram that lies.

### Six capabilities, six decisions that are easy to get quietly wrong

`test_runner`'s specification is a list of features. Each one turned out to contain a judgement:

- **Affected** asks git four questions and takes the union — committed, staged, unstaged, untracked. A pre-push hook that asked only the first would pass on work not yet committed, which is the one moment it exists to catch. A diff git cannot answer runs *everything*.
- **Runner selection** reads `sdk: flutter` from the pubspec, never the path: a `platform/*` package and an `_api` package live at the same depth.
- **Bundling** is a flag, not a default, because a library-level `@Tags` belongs to the file that carries it and a bundle is a different file.
- **Hash-skip** covers the package's dependencies' sources, or it would skip `routing_application` after a change to `core_kernel` — the one case the cache exists to get right.
- **Bucketing** is by measured cost, not count. Ties break on name, so a flake can be reproduced on the machine that saw it.
- **Reporting** is one JUnit case per *package*: parsing two machine reporters into per-test cases would make this a third, worse test framework.

### The earliest gate that can afford it

Every check in the pipeline is placed by one rule, and `docs/CI_CD.md` names it for each. Two pairs that look redundant and are not: `fetch-depth: 0` **and** an explicit `git fetch origin main` (checkout gives you history, not that ref, and two tools name it); `arch_check` on both hooks (the `skip:` block leaves merge commits unchecked, so pre-push is the last local gate that sees one).

## Packages added

| Package | Tests | What it is for |
|---|---|---|
| `tooling/dep_graph` | 20 | the graph, four views, cycle detection, staleness gate |
| `tooling/test_runner` | 41 | affected selection, runner choice, bundling, hash-skip, bucketing, JUnit |

## Files added

`.github/workflows/{pr,main,nightly,release}.yml`, `.github/CODEOWNERS`, `.github/pull_request_template.md`, `.github/ISSUE_TEMPLATE/{config,bug,architecture}.yml`, `codemagic.yaml`, `fastlane/Fastfile`, `docs/{ARCHITECTURE,TESTING,CI_CD,dependency-graph}.md`.

## Known gaps

**`codemagic.yaml` and `fastlane/Fastfile` cannot run against this repository as it stands.** There is no `apps/*/android/`, no `apps/*/ios/` and no `apps/*/config/<flavour>.json` — the specification explicitly does not require iOS or Android builds, so the native projects were never generated. Both files state this at the top and `docs/CI_CD.md` §7 repeats it; everything else in them is real.

**No golden test and no integration test exists.** The tags, the presets, the CI steps and the exclusions are all wired. Wiring first is deliberate: a golden added to a repository with no tag, no preset excluding it and no nightly running it becomes a flaky pull-request check within a week and then gets deleted.

**Branch protection is a repository setting, not a file.** The required status checks — the `pr` workflow's `verify` job and the merge queue's ten buckets — have to be enabled after this merges.

**Eight commits, at the low end of the 15–40 the constitution calls normal.** Each is a complete unit that passes every gate on its own; a cross-package contract change cannot be split further without commits that do not compile.

## Verification

```
dart analyze --fatal-infos --fatal-warnings .   No issues found!
dart run melos run arch:check                   clean — 75 packages, no violations
dart run melos run gen:check                    SUCCESS
dart run melos run graph:check                  docs/dependency-graph.md is current
dart run melos run test                         SUCCESS — 1,530 cases, 161 files
```
