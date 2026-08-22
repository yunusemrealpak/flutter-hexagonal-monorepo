## Phase 0 — Foundation and repository setup

Sets up the repository, the workspace root and the rule surface that every later phase is checked against. No product package is added in this phase; the point is that the rules exist before the code does.

### Scope

| Area | Delivered |
|---|---|
| Repository | `git init`, public GitHub repository, 10 topics, MIT `LICENSE`, `.gitignore`, `.gitattributes` |
| Entry points | `README.md` (showcase), `CLAUDE.md` (constitution), spec relocated to `docs/` |
| Workspace | Root `pubspec.yaml` as a Dart pub workspace, melos 8.3.0 as a dev dependency |
| Commands | melos scripts `format`, `format:check`, `analyze`, `gen`, `gen:all`, `gen:check`, `gen:watch`, `arch:check`, `test:affected` |
| Toolchain | Flutter 3.44.2 / Dart 3.12.2 pinned in `.fvmrc` and `.tool-versions` |
| Analysis | `analysis_options.yaml` on very_good_analysis 10.3.0, with two constitutional lints promoted to errors |
| Tests | `dart_test.yaml` with the `unit` / `widget` / `golden` / `integration` / `flaky` tags and the `pr` and `quarantine` presets |
| Hooks | `lefthook.yml` — pre-commit format + analyze, pre-push gen:check + arch:check + affected tests |
| Rules | `docs/DEPENDENCY_RULES.md`, the machine-checkable form of the constitution |

**Packages added: 0.** Phase 1 adds the first four (`core_kernel`, `core_ports`, `core_navigation`, `core_testing`).

### Which architectural rules become visible here

Phase 0 makes three rules enforceable before there is any code to enforce them on.

**Rule 1.2.5 — a package's public surface is its barrel.** `implementation_imports` is promoted from lint to error in the root `analysis_options.yaml`, so `package:x/src/...` stops compiling in the IDE, not just in CI. `arch_check` will later add the same check as `deep_import`, but the analyzer already covers the common case from the first package onwards.

**arch_check's central premise.** That tool reads pubspec files and treats them as the truth about a package's dependencies. `depend_on_referenced_packages` is promoted to error so that an import cannot exist without a matching pubspec entry — without it, the whole dependency check would be verifying a document rather than the code.

**Generated code is committed, and analyzed.** `.gitignore` deliberately omits `*.g.dart`, `*.freezed.dart`, `*.gr.dart` and `*.config.dart`, and `analysis_options.yaml` deliberately does not exclude them. Style noise is handled per-file by the generators' `// ignore_for_file: type=lint` header instead of per-project exclusion, so errors and type checks keep surfacing. `.gitattributes` marks them `linguist-generated` to keep review readable.

### Verification

`arch_check` does not exist until phase 3, so the rules were verified by hand and each commit body records what was verified.

```
$ dart pub get
Got dependencies!

$ dart run melos run analyze          # dart analyze --fatal-infos --fatal-warnings .
Analyzing ....
No issues found!

$ dart run melos run format:check
Formatted no files in 0.00 seconds.

$ git status --porcelain
(clean)
```

`dart_test.yaml` was validated against the real test runner in a sandbox package holding one test per tag: `--preset pr` selected only the `unit` test, `--preset quarantine` selected only the `flaky` one, and an unfiltered run selected all four.

The melos `gen`, `gen:all` and `gen:watch` scripts currently exit with `NoPackageFoundScriptException`, which is the correct result: their `dependsOn: build_runner` filter matches nothing while the workspace has no packages. They become live in phase 1.

**Test count: 0.** No product package exists yet.

### Known gaps

- `arch:check` and `test:affected` point at `tooling/arch_check` and `tooling/test_runner`, which arrive in phases 3 and 8. The pre-push hook guards both with a file-existence check and prints what is not being verified rather than passing silently.
- `docs/ARCHITECTURE.md`, `docs/TESTING.md`, `docs/CI_CD.md` and `docs/dependency-graph.md` are linked from `README.md` but are written in phases 4–8.
- Branch protection is applied at the end of this phase without a required status check; CI does not exist until phase 8, and that is when the status check requirement is added.
- `lefthook` is not installed on the development machine yet. The configuration is committed and validated as YAML; `lefthook install` is documented in `README.md`.
- `public_member_api_docs` is part of the very_good_analysis baseline and is kept on. Every public member added from phase 1 onwards needs a doc comment.
