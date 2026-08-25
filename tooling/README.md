# tooling

Programs that enforce and apply the architecture. None of them is part of the product: rule I7 forbids a tool from depending on anything under `packages/` or `apps/`, because a tool has to be able to read a workspace that does not compile — the only time one earns its place.

| Tool | Phase | What it does |
|---|---|---|
| [`arch_check`](arch_check) | 3 | Enforces the dependency constitution against the workspace |
| [`scaffold`](scaffold) | 3 | Generates a feature's packages with that constitution already obeyed |
| `test_runner` | 8 | Affected-test selection, runner choice, hash-skip, bucketing |
| `dep_graph` | 8 | Renders the dependency graph to `docs/dependency-graph.md` |

---

## `arch_check`

```bash
dart run melos run arch:check                                  # what hooks and CI run
dart run tooling/arch_check/bin/arch_check.dart --format=json  # for a machine
```

Reads its rules from [`arch_check/rules.yaml`](arch_check/rules.yaml), not from its own source — every rule, every violation code and every remedy string. [`docs/DEPENDENCY_RULES.md`](../docs/DEPENDENCY_RULES.md) stays the specification; when the two disagree, the document is right and the file is the bug.

Seven families of check, one per section of that document: package typing (§1), dependency edges (§2), structure (§3), forbidden imports (§4), forbidden APIs (§5), code generation (§6), and cycles (S7). Every violation it prints carries four fields — code, location, what, remedy — because a rule that does not say how to fix it gets worked around instead of obeyed.

| Exit code | Meaning |
|---|---|
| `0` | clean |
| `1` | violations found |
| `64` | the checker could not run — bad arguments, missing root, unreadable `rules.yaml` |

`64` is separate on purpose. A tool that exits `1` both for "the architecture is broken" and for "I could not read my own rules" teaches CI to treat the second as the first, and then a rule file that fails to parse reads as a clean workspace.

Two things worth knowing before changing it: sources are **parsed, not resolved** (resolution needs a working pub solution, which is exactly what a broken workspace lacks), and §5 is matched against the **AST, never against text** — every occurrence of `DateTime.now()` in this repository today sits inside a comment explaining why the call is banned.

## `scaffold`

```bash
dart run tooling/scaffold/bin/scaffold.dart new-feature --name billing --split full
dart run tooling/scaffold/bin/scaffold.dart new-feature --name faq --split reduced
dart run tooling/scaffold/bin/scaffold.dart new-feature --name shipments \
  --split full --with-testing --presentation courier,dispatcher
```

Writes each package's directory, a pubspec carrying exactly the dependency row §2 allows for that package type, a barrel, seed sources that compile and are tested, a `README.md` naming what must never live there, a `dart_test.yaml`, and the entry in the root `workspace:` list.

| Flag | |
|---|---|
| `--split full\|reduced` | `_api`/`_application`/`_infrastructure`/`_presentation`, or `_api`/`_core`/`_presentation` |
| `--presentation a,b` | One presentation package per app |
| `--with-testing` | Also `<feature>_testing`; only when another package's tests will use its fakes |
| `--codegen` | Write `build.yaml` and generator dev dependencies for the roles that generate |
| `--dry-run` / `--force` / `--root` | List instead of write / overwrite existing files / pick the workspace root |

Everything under `lib/src` in a generated package is a seed meant to be deleted. A scaffolded file that survives untouched into a real feature is a file nobody read.

---

## The discipline

The two tools are one loop, and the loop is what keeps the architecture from drifting.

```
   scaffold ──generates──►  packages that already obey §2
                                      │
                            you write the real code
                                      │
                                      ▼
                               arch_check ──►  0 violations
                                      ▲
                                      │
      arch_check/rules.yaml  ◄────────┴──────  docs/DEPENDENCY_RULES.md
             (the encoding)                        (the specification)
```

**Starting a feature.** Run the scaffolder, then `flutter pub get`, then `melos run analyze` and `melos run arch:check`. If either is red on a freshly generated feature, the scaffolder is wrong, not your workspace — that case is covered by its acceptance test and should never reach you.

**While working.** `arch_check` is cheap enough to run whenever you have added a dependency or moved a file. It reports the rule and the fix, not just the fact.

**Before each commit** (CLAUDE.md §5): `melos run gen`, `dart analyze`, `melos run arch:check`, plus the affected tests. The hooks enforce the split by cost rather than by importance. `pre-commit` formats and analyzes the staged files and runs `arch:check` over the workspace — the architecture check is there because learning at push time that an existing commit breaks the constitution is a bad trade, and it is affordable because the tool runs from a compiled snapshot rather than through `dart run`, which spends four seconds loading itself before it reads a file. `pre-push` runs the code generation gate and the tests, which are the two that genuinely cannot go on every commit; it repeats `arch:check` for one path only, since `skip: [merge, rebase]` means a merge commit has never met the pre-commit hook.

**Changing a rule** is a pull request that touches three things ([`docs/DEPENDENCY_RULES.md`](../docs/DEPENDENCY_RULES.md) §9):

1. the document — the rule and why it exists,
2. `arch_check/rules.yaml` — the machine form, and its remedy text under `messages`,
3. a fixture under `arch_check/test/fixtures/` proving the new behaviour fires, checked against `clean` so it does not fire anywhere else.

A rule with no fixture is a rule that will silently stop working. And if the change affects what a new package should look like, `scaffold`'s templates and `feature_plan.dart` move in the same commit — its acceptance test runs `arch_check` over freshly generated features, so a constitution the scaffolder no longer follows fails there before anyone meets it in real code.

**When a rule feels like it needs bending: stop and report it instead of bending it.** Three rules resist a checker altogether and stay a review responsibility — whether a cycle was resolved with contracts or with a new `shared` package, whether a mapper really maps, and whether an adapter has quietly taken on a use case's job.

---

## Why the scaffolder is not a melos script

Melos scripts exist to give a stable name to something CI files, git hooks and documentation reference repeatedly, so the command surface stays fixed while the command underneath changes. `format`, `analyze`, `gen`, `arch:check` and `test` are all that; the scaffolder is not. Nothing automated calls it, it runs a handful of times per phase, and it is invoked by a person.

There is also a mechanical reason. Melos 8 does not forward extra arguments to a script — `melos run arch:check --format=json` has melos parse `--format` as its own flag, and `melos run -- arch:check --help` fails to resolve the script at all. A `new-feature` script therefore could not take `--name`, which is the entire point of the invocation.
