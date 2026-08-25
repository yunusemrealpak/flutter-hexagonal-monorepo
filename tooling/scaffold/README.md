# scaffold

Generates a feature's package skeleton, with the dependency lists the constitution allows and nothing more.

```bash
dart run tooling/scaffold/bin/scaffold.dart new-feature --name billing --split full
dart run tooling/scaffold/bin/scaffold.dart new-feature --name faq --split reduced
dart run tooling/scaffold/bin/scaffold.dart new-feature --name shipments \
  --split full --with-testing --presentation courier,dispatcher
```

Then `dart pub get`, `dart run melos run analyze`, `dart run melos run arch:check`.

| Flag | What it does |
|---|---|
| `--name` | The feature, in `lower_snake_case`. Anything pub would reject is refused. |
| `--split` | `full` (`_api`, `_application`, `_infrastructure`, `_presentation`) or `reduced` (`_api`, `_core`, `_presentation`). |
| `--presentation` | One presentation package per value, suffixed with it. Omit for a single `<feature>_presentation`. |
| `--with-testing` | Also create `<feature>_testing`. Create it only when another package's tests will consume its fakes. |
| `--codegen` | Write a `build.yaml` and the matching dev dependencies for the roles that conventionally generate. |
| `--dry-run` | Write nothing; list what would be written. |
| `--force` | Overwrite files that already exist. Off by default, so the tool can be re-run on a feature that exists. |
| `--root` | The workspace root. Defaults to the current directory. |

## What it may depend on

Third-party Dart packages, and nothing in `packages/` or `apps/` — rule I7. It writes files and splices one YAML list; it never imports what it generates. Even the test that checks its output against `arch_check` runs the checker as a **subprocess** rather than importing it.

## What must never live here

- **A dependency list that disagrees with `docs/DEPENDENCY_RULES.md` §2.** The tables in `feature_plan.dart` are that document, one row per role. When the document changes, they change in the same commit, and `feature_plan_test.dart` is what fails if they do not.
- **A template that is only correct for some feature names.** See below — this is the failure mode this package is most exposed to.
- **Anything the generated feature would have to undo.** A scaffolded file that has to be edited before the first commit is worse than an absent one.

## Two decisions worth knowing about

**Generated Dart is formatted before it is written.** `dart format`'s output depends on identifier length, so a template that is correctly formatted for `billing` is wrong for `vehicle_inventory` — the line that fitted now wraps. Left to the templates, the failure would surface as a red `format:check` in whoever ran the tool, not in this package's tests. The same class of bug bites the pubspec (`sort_pub_dependencies`: an SDK dependency on `flutter` sorts before `vehicle_inventory` and after `billing`) and the import blocks (`directives_ordering`: `billing_api` sorts before `core_kernel`, `faq_api` after). All three are computed rather than written out, and `templates_test.dart` runs every assertion against a feature on each side of that line.

**A dependency that does not exist yet is left out.** `design_system` arrives in phase 5, and a presentation package generated before then still has to run `dart pub get`. The scaffolder checks the root workspace list, omits what is not there, and says so on stdout — an omission nobody is told about is a bug waiting to be found later.

## Code generation

`--codegen` is off by default, and the default is the one the constitution asks for: a package with no generated files has no `build.yaml` and no `build_runner` dependency, and that is the cheapest configuration rather than a missing one (CLAUDE.md §7.6). A freshly scaffolded feature generates nothing, so it gets nothing. Each generated README says which builder to enable when the first annotated type arrives.

`--codegen` exists for the other reading — the specification's "the scaffolder puts the correct `build.yaml` in every package it produces" — and for the case where you already know the feature will need `freezed` on day one. What it writes is per role: `freezed` in `_api`, `json_serializable` in `_infrastructure` and `_core`, `go_router_builder` in `_presentation`, each narrowed with `generate_for` and none of them in a package that rule G2 or G3 forbids.

The generator versions are pinned rather than left open. The workspace shares one dependency solution, so a generator that wants an older `analyzer` than `arch_check` does makes the whole repository unresolvable — and the error pub prints for that names two packages with nothing to do with each other.

## The seeds

Everything under `lib/src` in a generated package compiles, is covered by a test, and is meant to be deleted. They are there to show the shape: a sealed failure hierarchy and a port in `_api`, a use case whose collaborators arrive through its constructor in `_application`, an adapter that returns a `Failed` instead of throwing and a DTO that never crosses into the domain in `_infrastructure`, a `RouteModule` in `_presentation`, and a behavioural fake in `_testing`.

A scaffolded file that survives untouched into a real feature is a file nobody read.
