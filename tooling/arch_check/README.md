# arch_check

Enforces the dependency constitution in [`docs/DEPENDENCY_RULES.md`](../../docs/DEPENDENCY_RULES.md) against the workspace.

```bash
dart run tooling/arch_check/bin/arch_check.dart              # the whole workspace
dart run tooling/arch_check/bin/arch_check.dart --format=json # for a machine
dart run melos run arch:check                                 # what CI and the hooks run
```

Exit codes: **0** clean, **1** violations found, **64** the checker could not run. The third is separate on purpose — a tool that exits 1 both for "the architecture is broken" and for "I could not read my own rules" teaches CI to treat the second as the first.

## What it is for

Seven families of check, one per section of the dependency rules:

| Check | Enforces | Codes |
|---|---|---|
| `DependencyCheck` | §2, every pubspec edge against the whitelist for that package type | `forbidden_dependency`, `tooling_depends_on_product`, `dev_dependency_in_lib` |
| `StructureCheck` | §3 minus the cycle: barrels, stray files, naming, registration, deep imports, implementation in a contract package | `missing_barrel`, `stray_lib_file`, `barrel_leak`, `name_mismatch`, `unregistered_package`, `deep_import`, `implementation_in_api` |
| `ImportCheck` | §4 | `kernel_dependency`, `flutter_in_pure_dart`, `technology_in_domain`, `serialization_in_api`, `locator_outside_app`, `annotation_di_outside_app` |
| `ApiCheck` | §5, against the AST | `ambient_clock`, `ambient_random`, `ambient_id`, `ambient_print`, `exception_at_port_boundary` |
| `CodegenCheck` | §6 | `codegen_in_kernel`, `serialization_in_api`, `annotation_di_outside_app`, `unpinned_builders` |
| `CycleCheck` | S7 | `dependency_cycle` |
| the loader | §1 | `unknown_package_type` |

Every violation carries four fields — code, location, what, remedy — because a rule that does not say how to fix it gets worked around instead of obeyed.

## What it may depend on

Third-party Dart packages, and nothing in `packages/` or `apps/`. That is rule I7, and it is not bureaucracy: a tool has to be able to analyze a workspace that does not compile, which is the only time an architecture checker earns its place. `arch_check` reads pubspecs, source and `build.yaml` off the filesystem and imports none of them.

## What must never live here

- **The rules.** They live in [`rules.yaml`](rules.yaml), next to the document they encode. A rule change should be reviewable by someone who does not read Dart, and every message and remedy the tool prints comes out of that file.
- **A dependency on the product.** See above.
- **A rule with no fixture.** §9 of the dependency rules is the process: a pull request that changes a rule touches the document, `rules.yaml`, and a fixture under `test/fixtures/` proving the new behaviour. A rule with no fixture is a rule that will silently stop working.

## Two decisions worth knowing about

**Sources are parsed, not resolved.** Resolution would need a working pub solution for every package — exactly what a workspace in trouble does not have — and it is the difference between a run measured in hundreds of milliseconds and one measured in minutes. Every rule here is decidable from syntax: an import URI is a string, and §5 is about the *shape* of a call rather than about which declaration it binds to.

**§5 is matched against the AST, never against text.** Two failure modes make the naive grep useless, and both were observed while writing the core packages. A doc comment that quotes the rule it explains trips a text search — `core_ports/clock.dart` documents itself with "no line of product code calls `DateTime.now()`", and today *every* occurrence of that call in the workspace is inside such a comment. And a pattern of `DateTime.now()` with an unescaped `.` matches the declaration `DateTime now()`, which is the port itself. Generated files are exempt from §5 and from nothing else: a `DateTime` in generated output is not the developer's choice, but a generated file importing a forbidden package is a real violation regardless of who typed it.
