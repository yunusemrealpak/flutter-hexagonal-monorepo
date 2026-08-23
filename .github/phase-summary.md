## Phase 1 — Core packages

The four packages every other package in the workspace is allowed to depend on. Nothing here knows anything about couriers, shipments or payments; this phase is the vocabulary, not the domain.

### Packages added: 4

| Package | Public surface | Depends on |
|---|---|---|
| `core_kernel` | `Result`, `Failure`, `ValueObject`, `Entity`, `UseCase`, `DomainEvent` | **nothing** |
| `core_ports` | 11 ports + `StoreFailure`, `SecureStoreFailure` | `core_kernel` |
| `core_navigation` | `RouteLocation`, `RouteDefinition`, `RouteModule`, `Navigation` | `core_kernel` |
| `core_testing` | 12 behavioural fakes | `core_kernel`, `core_ports`, `core_navigation` |

`core_ports` declares `Clock`, `IdGenerator`, `RandomSource`, `Logger`, `NetworkStatus`, `KeyValueStore`, `SecureStore`, `AnalyticsSink`, `FeatureFlagReader`, `DomainEventBus` and `PermissionRequester`. `core_testing` provides a fake for each, plus `RecordingNavigation`.

### Which architectural rules become visible here

**The innermost ring pays for everything.** `core_kernel` has an empty `dependencies:` block, no `build_runner`, and no `build.yaml`. Everything may depend on it, so a dependency added here is a dependency added everywhere and a rebuild here is a rebuild everywhere. That cost, not taste, is what keeps the package at six types.

**Ports are declared, never implemented.** `core_ports` contains not one implementation. The adapters arrive in phase 2, the fakes are in `core_testing`, and the two never meet outside an app's composition root. `Logger` shows the corollary: the interface carries a single method so implementing it stays a one-method job, and the four severities developers actually type are extension methods that cost the contract nothing.

**Determinism is structural, not disciplined.** `Clock`, `IdGenerator` and `RandomSource` exist so that no product code calls `DateTime.now()`, `Uuid()` or `Random()`. `DomainEvent` makes `occurredAt` required with no default, so the only way to construct an event is to have asked a `Clock` first — the rule is enforced by the type, not by review.

**Failure is a value, and denial is not failure.** `KeyValueStore` and `SecureStore` return `Result`; `PermissionRequester` and `FeatureFlagReader` do not. A denied camera permission is a product path a courier still has to complete a delivery through, and an unreachable flag service answers with the caller's `orElse`. Neither is an error to report.

### Decisions that needed a ruling

Three rules turned out to be under-specified once real code hit them. All three are now settled in `CLAUDE.md` and `docs/DEPENDENCY_RULES.md`, in their own commits ahead of the code:

1. **`Result` for infallible ports.** Invariant 1.2.9 says every port method returns `Result`, but its second clause declares failure types in the owning `_api` package — so the rule was written for feature ports. Applied literally to `Clock.now()` it would put an unreachable `Failed` branch at every call site. Ruling: `Result` when the operation can fail, a plain value when it cannot; the prohibition on throwing still applies to every port without exception.
2. **"Depends on nothing" and the test harness.** `core_kernel` is specified as depending on nothing, but every package needs `package:test`. The rules now scope to `dependencies:` and imports under `lib/`, with a new violation code (`dev_dependency_in_lib`) for the case that actually matters.
3. **`build.yaml` in packages with no codegen.** The new-package checklist demanded one from every package. A package with no `build_runner` dependency has no builder to disable, so the absence of the file is the cheapest correct configuration.

### Lint conflict, resolved once at the root

`one_member_abstracts` is disabled workspace-wide. A port is usually a named interface with a single method — `Clock`, `IdGenerator`, `RandomSource` — and the rule would have each of them replaced by a bare function type, deleting the name of the capability, the place its documentation lives, and the declaration that a fake and a real adapter are the same thing. Turning it off once is honest about the conflict; scattering forty ignore comments across `core_ports` and the feature `_api` packages would disguise a deliberate choice as accumulated debt.

### Verification

`arch_check` does not exist until phase 3, so the rules were verified by hand and each commit body records what was verified.

```
$ melos run analyze          # dart analyze --fatal-infos --fatal-warnings .
No issues found!

$ melos run format:check
Formatted 57 files (0 changed)

$ dart test --preset pr      # per package
core_kernel      28 tests
core_ports        5 tests
core_navigation   9 tests
core_testing     38 tests
                 ── 80 tests, all passing
```

Structural checks, by hand:

| Rule | Result |
|---|---|
| I1 — `core_kernel` imports nothing under `lib/` | empty `dependencies:` block |
| I2 — no `flutter` in pure Dart packages | 0 `package:flutter` imports across `packages/core/` |
| A1–A4 — no ambient clock, random or print | 0 in code; 3 hits are doc comments quoting the rule |
| S2 — barrel is the only file under `lib/` | 4 of 4 |
| S5 — package name equals directory name | 4 of 4 |
| S6 — registered in the workspace list | 4 of 4 |
| G1 — no generated file or `build.yaml` in `core_kernel` | 0 |

**Test count: 80.**

### Two bugs the tests caught, worth reading

`FakeNetworkStatus.changes()` was first an `async*` generator. An async generator does not subscribe to the underlying stream until after its first yield is delivered, so a test that subscribed and immediately drove a transition silently lost it. It now uses `Stream.multi`, whose callback runs synchronously on listen. A fake with a race in it is worse than no fake — the tests it breaks look like bugs in the code under test.

`Result` equality delegates to the wrapped value's `==`, and Dart collections compare by identity, so `Success({'a'}) != Success({'a'})`. Deep equality was rejected: it needs a collection-equality helper, and `core_kernel` is the one package allowed no third-party dependency. The `core_kernel` README documents the unwrap-before-asserting pattern instead.

### Known gaps

- `melos run gen`, `gen:all` and `gen:watch` still exit with `NoPackageFoundScriptException`. Their filter is `dependsOn: build_runner`, and none of the four core packages uses code generation — by design. The scripts become live in phase 2 with `storage_drift`.
- `arch:check` and `test:affected` still point at tooling written in phases 3 and 8. The pre-push hook guards both and says what it is not verifying.
- A new rule was added to `docs/DEPENDENCY_RULES.md` this phase: A1–A4 must be matched against the AST, not against text. Verifying by hand produced three false positives out of five hits — comments that quote the rule, and an unescaped `.` in `DateTime.now()` matching the declaration `DateTime now()`. Phase 3 must implement it that way.
- `public_member_api_docs` is on and every public member in these four packages carries a doc comment. That is the intended standard for a reference repository and it is a real cost in the feature phases.
