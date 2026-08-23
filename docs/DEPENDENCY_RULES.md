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
| `feature_testing` | own `_api`, `core_kernel`, `core_ports`, `core_testing` | any implementation package |
| `platform` | `core_kernel`, `core_ports` | any feature package, any other `platform/*` |
| `design_tokens` | the `flutter` SDK only | everything else |
| `design_system` | `design_tokens`, `core_kernel`, the `flutter` SDK | any feature package, any `platform/*` |
| `tooling` | third-party Dart packages only | every product package in `packages/` and `apps/` |
| `app` | anything | nothing |

Third-party packages are unrestricted except where §4 forbids them explicitly.

### 2.0 What "depend on" means

The rules in this section apply to the `dependencies:` block of a pubspec and to imports under `lib/`. Two things are deliberately outside their scope:

- **`dev_dependencies:` used only by `test/`.** Every package needs a test harness, and `package:test` is not an architectural dependency — it never ships, and nothing under `lib/` may import it. `core_kernel` therefore has `test` in `dev_dependencies` while still having an empty `dependencies` block, and that is not a violation of "depends on nothing". `arch_check` reads `dependencies:` for edge validation and scans `lib/` for imports; a package that imports a dev dependency from `lib/` is a violation (`dev_dependency_in_lib`).
- **`build_runner` and generator packages.** They are dev dependencies for the same reason: they run at build time and produce source, they are not part of the package's runtime surface.

### 2.1 Notes on the two edges people get wrong

**`feature_infrastructure` may not depend on a foreign `_api`.** An adapter translates between one feature's ports and one technology. If it needs a concept from another feature, the concept belongs in its own `_api` and the *use case* — not the adapter — should be doing the crossing.

**`feature_application` may not depend on `platform/*`.** Platform packages are driven adapters. An application package that reaches for one has stopped being pure Dart and has stopped being testable without a device.

---

## 3. Structural rules

| ID | Rule | Violation code |
|---|---|---|
| S1 | Every package has a barrel at `lib/<package_name>.dart`. | `missing_barrel` |
| S2 | That barrel is the only `.dart` file directly under `lib/`. Everything else lives under `lib/src/`. | `stray_lib_file` |
| S3 | No file imports `package:<other_package>/src/...`. Within its own package, relative imports into `src/` are fine. | `deep_import` |
| S4 | A barrel exports nothing that leaks an internal type it does not intend to publish. | `barrel_leak` |
| S5 | The `name:` in `pubspec.yaml` equals the directory name. | `name_mismatch` |
| S6 | The package path is registered in the root `pubspec.yaml` `workspace:` list, and the package declares `resolution: workspace`. | `unregistered_package` |
| S7 | The dependency graph is acyclic. | `dependency_cycle` |
| S8 | An `_api` package contains no implementation class — no class that implements or extends a port declared in the same package, and no concrete adapter. | `implementation_in_api` |

S3 is additionally enforced by the analyzer: `implementation_imports` is promoted to `error` in the root `analysis_options.yaml`.

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

---

## 5. Forbidden APIs

| ID | Forbidden call | Use instead | Violation code |
|---|---|---|---|
| A1 | `DateTime.now()` | `Clock` from `core_ports` | `ambient_clock` |
| A2 | `Random()`, `Random.secure()` | `RandomSource` from `core_ports` | `ambient_random` |
| A3 | `Uuid()` and equivalents | `IdGenerator` from `core_ports` | `ambient_id` |
| A4 | `print()` | `Logger` from `core_ports` | `ambient_print` (also covered by the `avoid_print` lint) |
| A5 | `throw` across a port implementation's public boundary | return a `Result<S, F>` with a `sealed` failure | `exception_at_port_boundary` |

**Matching.** A1–A4 are checked against parsed source, not against a text search. Two failure modes make the naive grep useless, and both were observed while writing the core packages in phase 1:

- **Comments quoting the rule.** `core_ports/clock.dart` documents itself with "this port exists so that no line of product code calls `DateTime.now()`". Every doc comment that explains why a rule exists trips a checker that scans raw text, and the packages most careful about the rule trip it most often.
- **Regex metacharacters.** A pattern of `DateTime.now()` with an unescaped `.` matches the declaration `DateTime now()` — the port itself — because the dot matches the space.

`arch_check` therefore walks the analyzed AST and reports method invocations and instance creations, ignoring comments and string literals entirely.

**Scope.** A1–A4 are checked in every package except `apps/*` (where the composition root supplies the real implementations) and `tooling/*` (which is not part of the product). Generated files (`*.g.dart`, `*.freezed.dart`, `*.gr.dart`, `*.config.dart`) are exempt from A1–A4, because a `DateTime` in generated output is not the developer's choice. Generated files are **not** exempt from §2, §3 or §4: a generated file importing a package the constitution forbids is a real architectural violation regardless of who typed it.

---

## 6. Code generation rules that are machine-checked

| ID | Rule | Violation code |
|---|---|---|
| G1 | `core_kernel` contains no generated file and no `build.yaml`. Regeneration cost in the innermost ring spreads to the whole repository. | `codegen_in_kernel` |
| G2 | `json_serializable` is not enabled in any `feature_api` package's `build.yaml`, and no `json_annotation` import appears there. This is the machine check for "DTOs are never declared in `_api`". | `serialization_in_api` |
| G3 | `injectable_generator` is enabled only in `apps/*`. | `annotation_di_outside_app` |
| G4 | Every package that has generated files has a `build.yaml` that enables the builders it needs and disables the rest explicitly. An unconfigured package makes build_runner scan every builder, which is significant waste at 74 packages. | `unpinned_builders` |
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

`--format=json` emits the same four fields per violation. Exit code is 1 when any violation is found.

---

## 8. The rules that are not mechanical

Three constitutional rules resist a checker and stay a review responsibility. They are listed here so that nobody mistakes "arch_check is green" for "the architecture is intact".

- **Rule 1.2.6, cycle resolution.** `arch_check` detects a cycle, but it cannot tell you that the right fix is mutual `_api` dependencies rather than a new `shared` package. Creating `shared` makes the graph green and the architecture worse.
- **Rule 1.2.10, DTO/entity separation.** The checker can prove a DTO is not declared in `_api`. It cannot prove that a mapper in `_infrastructure` actually maps rather than passing a DTO-shaped entity through.
- **Rule 4 of §2.1, adapter scope.** Whether an adapter has quietly taken on a use case's job is a judgement about intent, not about imports.

---

## 9. Changing these rules

Rules change through a pull request that touches this document, `tooling/arch_check/rules.yaml` and a fixture under `tooling/arch_check/test/fixtures/` proving the new or changed rule fires. A rule with no fixture is a rule that will silently stop working.
