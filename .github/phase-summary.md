# Phase 3 — `arch_check` and `scaffold`

Two tooling packages. From this phase on, the dependency constitution is enforced by a program rather than by attention, and a new feature is generated with it already obeyed.

## Scope

| | |
|---|---|
| Packages added | 2 — `tooling/arch_check`, `tooling/scaffold` |
| Workspace total | 15 packages |
| Commits | 15 |
| Tests | **325** across the workspace, of which **99** are new (42 in `arch_check`, 57 in `scaffold`) |

Nothing under `packages/` changed. The two documents that describe the rules did: `docs/DEPENDENCY_RULES.md` now states the mechanical reading of four rules that were written for a human reader, and `CLAUDE.md` §7 describes a scaffolder that exists instead of one that will.

## What became visible in this phase

**A rule that cannot be checked is a rule that is already being broken somewhere.** Writing the checker forced four sentences in the constitution to become decidable, and each one taught something:

- **S4, "a barrel leaks nothing"** → *a barrel re-exports and does nothing else*. The original wording asks about intent. The mechanical version asks two questions with answers: does the barrel declare a type, and does it republish another package's URI.
- **A5, "`throw` across a port's public boundary"** → *a `throw` or `rethrow` in a member whose declared return type is a `Result`, or a Future/FutureOr/Stream of one*. The original needs to know what a port is; the mechanical one only needs to know what the method promised, which is the same thing said in the type system.
- **G4, "enables the builders it needs and disables the rest explicitly"** → the second half is **not** checkable, and this is the interesting one. Naming a builder that is not a dev dependency of the package *fails* the build rather than tightening it, so "the rest" is only ever the rest that is present — which is why `push_messaging`'s `build.yaml` names `json_serializable` and not `freezed`. What is checked is what is decidable: a `build.yaml` exists, it turns something on, and everything it turns on is narrowed with `generate_for`.
- **§1, "derived from its path and name"** → *the directory name, not the pubspec's `name:`*. They are required to be equal by S5, so the choice is invisible until they disagree — and then believing the pubspec drops the package out of every type and replaces one obvious violation with silence about the other twenty.

**§5 has to be checked against an AST, and the workspace proves it.** Every occurrence of `DateTime.now()` in this repository today is inside a comment explaining why the call is banned; `core_ports/clock.dart` documents the port with the very call it exists to remove. A text-scanning checker reports the packages most careful about a rule the loudest. The `broken_apis` fixture is written the same way on purpose, so the test that counts five violations is also the test that proves comments are not scanned.

**The scaffolder's failure mode is the name it was first tried with.** Three separate lints — `sort_pub_dependencies`, `directives_ordering`, `lines_longer_than_80_chars` — break only for feature names on one side of a sort boundary or past a length. `billing_api` sorts before `core_kernel`; `faq_api` sorts after it. A hand-written template passes the first time anyone tries the tool and fails in someone's first commit. All three are computed at render time, generated Dart goes through `dart_style` before it is written, and `templates_test.dart` runs every assertion against a feature on each side of that line.

## `arch_check`

Reads `tooling/arch_check/rules.yaml` — every rule, every violation code and every remedy string. Sources are **parsed, not resolved**: resolution needs a working pub solution for every package, which is exactly what a workspace in trouble does not have, and every rule in the constitution is decidable from syntax.

| Check | Section | Codes |
|---|---|---|
| loader | §1 | `unknown_package_type` |
| `DependencyCheck` | §2 | `forbidden_dependency`, `tooling_depends_on_product`, `dev_dependency_in_lib` |
| `StructureCheck` | §3 (S1–S6, S8) | `missing_barrel`, `stray_lib_file`, `barrel_leak`, `name_mismatch`, `unregistered_package`, `deep_import`, `implementation_in_api` |
| `ImportCheck` | §4 | `kernel_dependency`, `flutter_in_pure_dart`, `technology_in_domain`, `serialization_in_api`, `locator_outside_app`, `annotation_di_outside_app` |
| `ApiCheck` | §5 | `ambient_clock`, `ambient_random`, `ambient_id`, `ambient_print`, `exception_at_port_boundary` |
| `CodegenCheck` | §6 | `codegen_in_kernel`, `serialization_in_api`, `annotation_di_outside_app`, `unpinned_builders` |
| `CycleCheck` | S7 | `dependency_cycle` |

Every violation carries four fields — code, location, what, remedy — in both formats. Three exit codes, not two: **0** clean, **1** violations, **64** could not run. A tool that exits 1 both for "the architecture is broken" and for "I could not read my own rules" teaches CI to treat the second as the first.

Eight fixtures under `test/fixtures/`, each a real mini workspace with real pubspecs. `clean` obeys every rule, so any violation reported against it is a false positive and every other fixture's count means something. Each test asserts the **exact multiset** of codes rather than containment: containment lets a rule start firing everywhere and still pass, and a checker that cries wolf is worked around within a week.

```
$ dart run melos run arch:check
arch_check: clean — 15 packages, no violations.
```

## `scaffold`

```bash
dart run tooling/scaffold/bin/scaffold.dart new-feature --name billing --split full
dart run tooling/scaffold/bin/scaffold.dart new-feature --name faq --split reduced
dart run tooling/scaffold/bin/scaffold.dart new-feature --name shipments \
  --split full --with-testing --presentation courier,dispatcher
```

Each generated package gets a pubspec whose dependency list is one row of §2 and nothing more, a barrel, seed sources that compile, a test that passes, a `README.md` naming what must never live there, a `dart_test.yaml`, and an entry in the root `workspace:` list. `--codegen` adds the `build.yaml` and dev dependencies for the roles that generate; `--dry-run`, `--force` and `--root` do what they say.

Its acceptance test generates five shapes into a throwaway workspace and runs `arch_check` over each as a **subprocess** — rule I7 applies to tools too, and running the real binary against the real rule file is the only way the test proves what it claims.

The seeds are meant to be deleted. They exist to show the shape: a sealed failure hierarchy and a port in `_api`, a use case whose collaborators arrive through its constructor in `_application`, an adapter that returns a `Failed` instead of throwing and a DTO that never crosses into the domain in `_infrastructure`, a `RouteModule` in `_presentation`, a behavioural fake in `_testing`.

## Acceptance

| Criterion | Result |
|---|---|
| `dart analyze --fatal-infos --fatal-warnings .` | clean |
| `dart run melos run format:check` | clean, 233 files |
| `dart run melos run arch:check` | clean, 15 packages, 0 violations |
| `dart run melos run gen:check` | clean |
| `dart run melos run test` | 325 passing |
| `arch_check` fixtures | 8 workspaces, every rule proved to fire |
| scaffold output compiles, tests, and passes `arch_check` | yes, for both splits, multiple presentation packages, and `--codegen` |

## Known gaps, and one rule to decide in phase 7

**Rule S1 will meet `apps/` in phase 7.** The document says *every* package has a barrel at `lib/<package_name>.dart`, and `rules.yaml` encodes that for every type including `app`. A Flutter application conventionally has `lib/main.dart` instead. This is flagged rather than pre-decided: phase 7 either gives each app a barrel or amends §3 through the process in §9. It is not bent here.

**Third-party dependencies in `core_ports`, `core_navigation` and `core_testing`.** §2's table says those may not depend on "everything else", and its closing sentence says third-party packages are unrestricted except where §4 forbids them. `rules.yaml` follows the closing sentence, and only the two rows that name third-party code in so many words — `core_kernel` and `design_tokens` — forbid it. The reading is recorded in a comment in `rules.yaml`; if the intent was stricter, that is a one-line change plus a fixture.

**`--codegen` resolves a tension rather than hiding it.** The specification says the scaffolder puts the correct `build.yaml` in every package it produces; `CLAUDE.md` §7.6 says a package with no generated files has no `build.yaml` and no `build_runner` dependency, and calls that the cheapest configuration rather than a missing one. A freshly scaffolded feature generates nothing, so the default follows §7.6 and the flag serves the other reading.

**Three rules stay a review responsibility** (§8 of the dependency rules): whether a cycle was resolved with contracts or with a new `shared` package, whether a mapper really maps, and whether an adapter has quietly taken on a use case's job.

**`test_runner` and `dep_graph` are phase 8.** `melos run test:affected` still falls back to the whole `pr` preset, and `docs/dependency-graph.md` does not exist yet, so the "graph with no cycles" criterion is currently proved by `arch_check`'s `CycleCheck` rather than by a rendered graph.
