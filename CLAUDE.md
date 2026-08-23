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
| `<feature>_testing` | own `_api`, `core_kernel`, `core_ports`, `core_testing` |
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
| `dart run melos run gen:check` | `gen` + `git diff --exit-code` | CI staleness gate |
| `dart run melos run gen:watch` | one package | while working on that package |

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

**Before every commit**, these three must be clean:

```bash
dart run melos run gen
dart analyze
dart run tooling/arch_check/bin/arch_check.dart
```

Plus the tests of the affected packages. Before `arch_check` exists (phases 0–2), verify the rules by hand and state in the commit body which rule you verified.

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

Use the scaffolder once it exists (phase 3 onward):

```bash
dart run tooling/scaffold/bin/scaffold.dart new-feature --name billing --split full
dart run tooling/scaffold/bin/scaffold.dart new-feature --name faq --split reduced
```

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
