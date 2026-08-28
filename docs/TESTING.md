# Testing

The goal was never to write 100,000 tests. It was to build the machine that could carry them, and to demonstrate every mechanism with a representative example. This document is what that machine is and how to work inside it.

Where the numbers below are counts of this repository, they are counts as of the phase 8 branch: **1,530 test cases across 161 files in 75 packages.**

---

## 1. The pyramid, and why it leans this far

| Layer | Target | Today | Runs in |
|---|---|---|---|
| Pure Dart unit (`_api`, `_application`, `core_*`, `tooling`) | 80% | 797 (52%) | `dart test`, milliseconds |
| Controller and widget (`_presentation`, `apps`) | 15% | 84 `testWidgets` (5.5%) | `flutter test` |
| Golden (`design_system`, selected screens) | 4% | 0 | `flutter test --tags golden` |
| Integration | 1% | 0 | nightly |

The remaining cases are `_infrastructure` (128), `_core` (117) and `platform` (153) — adapter tests, which sit between the two ends of the pyramid and mostly run under `dart test` too.

**Goldens and integration tests are zero, and the mechanism for both is wired.** The tags, the presets, the CI steps and the exclusions all exist; the images arrive with the screens that need them. Wiring first is deliberate: a golden test added to a repository that has no `golden` tag, no preset excluding it and no nightly job running it becomes a flaky pull-request check within a week, and then gets deleted.

**Why 80% pure Dart is a structural target rather than a preference.** `_api` and `_application` have no Flutter dependency — that is rule 1.2.3 and it is not negotiable — so their suites start in milliseconds where `flutter test` costs seconds of engine start-up per package. Across 75 packages that difference is most of a full run. It also means the tests that encode the *rules* are the fastest ones in the repository, which is the incentive you want: the cheapest test to write is the one testing the thing that matters most.

---

## 2. Contract kits

A contract kit is a test suite written against a **port**, run against every implementation of it. Eleven of them ship here:

| Kit | Port | Implementations held to it |
|---|---|---|
| `runRouteOptimizerContract` | `RouteOptimizerPort` | local heuristic, remote solver, fake |
| `runRouteCacheContract` | `RouteCache` | key-value cache, in-memory fake |
| `runShipmentGatewayContract` | `ShipmentGateway` | REST adapter, fake |
| `runShipmentCacheContract` | `ShipmentCache` | drift-backed, fake |
| `runProofStoreContract` | `ProofStorePort` | local encrypted, remote, fake |
| `runPaymentsGatewayContract` | `PaymentsGateway` | REST adapter, fake |
| `runSettlementStoreContract` | `SettlementStore` | key-value, fake |
| `runSessionStoreContract` | `SessionStore` | secure-store backed, fake |
| `runOutboxStoreContract` | `OutboxStore` | drift, in-memory |
| `runCommandTransportContract` | `CommandTransportPort` | HTTP, fake |
| `runMessageStoreContract` | `MessageStore` | drift, fake |

```dart
// packages/features/routing/routing_infrastructure/test/local_heuristic_test.dart
runRouteOptimizerContract(() => LocalHeuristicOptimizer());

// packages/features/routing/routing_testing/test/fake_route_optimizer_test.dart
runRouteOptimizerContract(FakeRouteOptimizer.new);
```

**What a kit is for is not coverage — it is preventing the fake and the real thing from drifting apart.** A fake that accepts an empty stop list where the real adapter refuses one turns every test that uses it into a test of a system that does not exist. The kit makes that divergence a compile-or-fail event rather than a discovery made six months later in production.

**What belongs in a kit:** the behaviour the *port* promises. Ordering guarantees, what an empty input does, which failure a missing record produces, whether a write is visible to the next read.

**What does not:** anything only one implementation can do. A kit asserting a SQL index exists is a kit only the drift adapter can pass, which makes it not a contract.

A kit lives in the feature's `_testing` package, because both the fake and the real adapter have to be able to import it, and they live in different packages.

---

## 3. Fakes, not mocks

There is no mocking library in this workspace, and that is a decision rather than an omission.

A mock asserts **how** a collaborator was called. A fake **behaves** like the thing it stands in for. The first couples a test to the implementation it is testing — rename a method, rearrange two calls, and a passing test fails without anything being wrong. The second couples it to the contract, which is what the test was supposed to be about.

Rules for writing one:

1. **It goes in the package that declares the contract it imitates.** `FakeHttpTransport` ships from `http_dio`, because `HttpTransport` is declared there. `InMemorySecureStore` ships from `core_testing`, because `SecureStore` is declared in `core_ports`. A feature's port fakes ship from that feature's `_testing`.
2. **It passes the contract kit.** If there is no kit, write one before the second implementation exists.
3. **It is steerable, and steering is not part of the port.** `FakeGeoFence.standAt(900)` and `FakeClock.advance(...)` are methods a test calls; they are not on the interface. A fake whose steering leaked into the port would make every production caller able to move time.
4. **It fails the way the real thing fails.** `Result` with the same sealed failure type. A fake that only ever succeeds tests nothing about the branch that matters.
5. **`noSuchMethod` for the rest.** A test stand-in that implements one port and stubs the other twenty methods with plausible values is a stand-in that will quietly answer a question the test never meant to ask. Throwing is louder.

`core_testing` ships `FakeClock`, `FakeIdGenerator`, `FakeRandomSource`, `InMemoryKeyValueStore`, `RecordingLogger`, `RecordingEventBus` and `RecordingAnalyticsSink` — every `core_ports` capability, so that no feature has to write its own clock.

---

## 4. Hermeticity

Four rules, and each one exists because of a specific way a suite rots.

**No test uses the real clock.** `DateTime.now()` is banned by rule 1.2.8 and checked by `arch_check` against the AST. Time arrives through the `Clock` port, and a test moves it. A suite that reads the wall clock passes for eleven months and fails in the twelfth, at a boundary nobody was thinking about.

**No test uses the network.** Every HTTP path goes through `HttpTransport`, and `FakeHttpTransport` ships from the package that declares it. A test that reaches a real service is a test whose result depends on somebody else's deployment.

**No test shares global state.** No `GetIt` inside a package (rule 1.2.7), no singletons, dependencies through constructors. This is what makes `-j <cores>` safe: two tests running at once cannot see each other.

**No test retries by default.** `dart_test.yaml` sets `retry: 0` at the top level in every package. Retries are granted to one thing only — the `flaky` tag — and that is a quarantine, not a setting.

---

## 5. Tags, presets and what each run selects

Every package carries a `dart_test.yaml` mirroring the workspace template:

```yaml
retry: 0
timeout: 30s

tags:
  unit:
  widget:
  golden:
  integration:
  flaky:
    retry: 2
    timeout: 2x

presets:
  pr:
    exclude_tags: golden || integration || flaky
  quarantine:
    include_tags: flaky
```

| Command | Selects | Where it runs |
|---|---|---|
| `melos run test` | the `pr` preset, every package | a local full check |
| `melos run test:affected` | the `pr` preset, packages a diff can break | pre-push, pull request |
| `melos run test:bucket` | one machine's tenth of the full suite | merge queue |
| `flutter test --tags golden` | goldens only | pull request, when a UI package changed |
| `dart test --preset quarantine` | the flaky quarantine | by hand, when triaging |
| nightly | everything, no exclusions | 02:30 UTC |

That is the template at the repository root. **A package keeps only the tags it can actually produce** — a pure Dart package declares no `widget`, `design_system` declares no `integration` — because a tag nothing carries is a filter that selects nothing, and selecting nothing is not silent: `flutter test --tags golden` exits **79**, *No tests ran*, which every runner reads as a failure. Anything that filters by tag therefore has to choose what an empty selection means before it can be trusted; the `pr` workflow's golden step chooses "nothing to run" and greps for the tag rather than asking every package.

`flutter test` has no `--preset`, so the `pr` selection is spelled out as `--exclude-tags "golden || integration || flaky"` wherever a Flutter package runs. The tag *definitions* still come from each package's own `dart_test.yaml`, which is what keeps one package's timeout from becoming everybody's.

---

## 6. Flake management

A flaky test is worse than a missing one: it trains everybody to re-run CI without reading it, and the day it fails for a real reason nobody notices.

The process is three steps and no judgement calls:

1. **Tag it `flaky`.** It leaves `pr`, `test:affected` and the merge queue immediately. It keeps running under `quarantine` and in the nightly, so it is not forgotten.
2. **Open an issue naming the package and the suspected cause.** "Flaky" is not a cause. `storage_drift` failed once in phase 6 and has not since; the note in `CLAUDE.md` says to suspect concurrent access to the temporary SQLite files, which is a hypothesis somebody can test.
3. **Fix it or delete it within a sprint.** A test in quarantine for a month is a test nobody is going to fix, and keeping it is pretending otherwise.

**Do not add a retry to make a test pass.** `retry: 2` on the `flaky` tag exists to keep the quarantine run from being pure noise, not to make an unreliable assertion reliable.

The most common cause in a workspace like this one is not concurrency — it is a test that got its time, its identifier or its randomness from somewhere other than a port. Which is why rule 1.2.8 is checked by a tool rather than by review.

---

## 7. What `test_runner` changes about all of this

[`tooling/test_runner`](../tooling/test_runner/README.md) is what makes the numbers in the next section survivable. Two of its behaviours have consequences for how you write tests:

**Affected selection walks `dev_dependencies` too.** A change to `routing_testing` re-runs every package that consumes its fakes. This is why a contract kit can be trusted: breaking it cannot go unnoticed just because it breaks nobody's build.

**The hash-skip covers generated files.** §4.3 puts generated output in the repository, so it is part of a package's source, and a `.freezed.dart` that changed without its source changing re-runs the suite. That is the staleness you want caught.

**Bundling changes what tags mean.** `--bundle` compiles a package's test files into one entrypoint so the suite starts once instead of once per file. A library-level `@Tags` or `@TestOn` belongs to the file that carries it, and a bundle is a different file — so any run that filters by tag stays unbundled. In practice: the merge queue bundles, the pull request does not.

### A note on `freezed` and compile time

Generated union types cost compile time, and compile time is the fixed cost at the front of every pure Dart suite. A `_api` package on the hot path — one that half the workspace depends on and whose tests therefore run constantly — should not grow union cases it does not need. `ShipmentStatus` has seven states because the product has seven, not because a union is a nice way to hold data.

Build the habit of measuring rather than guessing: `.cache/timings.json` holds the duration of every package's last run, and a package whose compile time has grown out of proportion shows up there before anybody notices it in the wall clock.

---

## 8. How this shape reaches 100,000 tests

The projection is not a promise; it is an argument that the *structure* scales, made by putting plausible per-package numbers against a mature version of this product — roughly forty features rather than thirteen.

| Package type | Packages at maturity | Tests each | Total |
|---|---|---|---|
| `<feature>_api` | 40 | 500 | 20,000 |
| `<feature>_application` | 30 | 900 | 27,000 |
| `<feature>_core` | 10 | 600 | 6,000 |
| `<feature>_infrastructure` | 30 | 500 | 15,000 |
| `<feature>_presentation*` | 60 | 350 | 21,000 |
| `<feature>_testing` (kits × implementations) | 30 | 150 | 4,500 |
| `platform/*` | 15 | 250 | 3,750 |
| `core_*` | 4 | 400 | 1,600 |
| `design_*` | 2 | 500 | 1,000 |
| `apps/*` | 4 | 150 | 600 |
| `tooling/*` | 6 | 200 | 1,200 |
| | **231** | | **≈101,650** |

Three properties of the structure are what make that number workable, and none of them is about writing tests faster:

**Nobody ever runs 100,000 tests for one change.** `test_runner --affected` walks outwards from the diff. A change to one feature's `_presentation` package runs one package; a change to `core_kernel` runs everything, and that asymmetry is the graph telling the truth about blast radius.

**The full run is divided by measured cost, not by count.** Ten buckets, longest-processing-time first, from `.cache/timings.json`. Splitting by count would put one widget suite next to nine `_api` packages and leave nine machines idle.

**The expensive tests are the rare ones.** 80% of the target sits in packages with no Flutter dependency, which start in milliseconds. The pyramid is not an aesthetic preference — it is the reason the arithmetic above lands in tens of minutes rather than hours.

The fourth property is the one this whole repository is about: **a package with a wrong dependency is a package whose tests cannot be isolated.** If `_application` could see `_infrastructure`, its suite would need a database, and 27,000 fast tests would be 27,000 slow ones. The dependency rules are a testing strategy that happens to be enforced by a compiler.
