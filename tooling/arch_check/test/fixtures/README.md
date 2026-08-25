# Fixtures

Each directory here is a miniature workspace with a real root `pubspec.yaml`, real packages and real Dart sources. `arch_check` is pointed at one with `--root` and its output is asserted in [`../fixtures_test.dart`](../fixtures_test.dart).

They are workspaces rather than string constants in a test because that is what the tool actually reads: a pubspec, a directory layout, a `build.yaml`, a barrel. A fixture that faked any of those would prove the checker works against the fake.

| Fixture | What it is for |
|---|---|
| `clean` | A workspace that obeys every rule. **Any** violation reported here is a false positive, which makes every other fixture's count meaningful. It also doubles as the smallest worked example of the architecture: a kernel, a port package, a full-split feature, a technology package, and a tool. |
| `broken_dependencies` | §2 — a kernel with a third-party dependency, a feature reaching past another feature's contract, the Flutter SDK in a pure Dart package, a tool importing the product, and a dev dependency that reached `lib/`. |
| `broken_structure` | §3 — a missing barrel, a stray file under `lib/`, a barrel that declares and re-exports, a name that does not match its directory, a package outside the workspace resolution, a deep import, and an implementation inside a contract package. |
| `broken_cycle` | S7 — two contract packages that depend on each other. |
| `broken_imports` | §4 — one forbidden import of each kind, each in a package type that forbids it. |
| `broken_apis` | §5 — the four ambient calls and a throw out of a `Result`. Its class is documented with the very calls it makes, so it also proves that comments are not scanned. |
| `broken_codegen` | §6 — generation in the innermost ring, serialization wired into a contract package, and generated output with no `build.yaml`. |
| `unknown_type` | §1 — a package whose path and name resolve to no type at all. |

## Rules for adding one

1. **One fixture per rule family, not per rule.** A fixture that breaks one rule in isolation says nothing about interference between rules; a fixture that breaks a whole section at once says what the section costs when it is ignored.
2. **Assert the exact multiset of codes**, not merely that the expected one is present. Containment would let a rule start firing everywhere and still pass, and a checker that cries wolf is worked around within a week.
3. **Keep `clean` clean.** When a new rule is added, run it against `clean` first. If it fires there, the rule is wrong before the fixture is written.
4. **Write the fixture in the same commit as the rule.** §9 of `docs/DEPENDENCY_RULES.md`: a rule with no fixture is a rule that will silently stop working.

## Why these are excluded from analysis

The root `analysis_options.yaml` excludes `tooling/*/test/fixtures/**`. These packages have no pub resolution and are deliberately broken, so every `package:` URI in them is unresolvable and `dart analyze` would report dozens of errors that mean nothing. The exclusion is scoped to fixture directories under `tooling/` so that no product source can ever fall inside it.

`arch_check` skips them for a different reason and by a different mechanism: `test` is on the discovery skip list in `rules.yaml`, so a run against the real workspace never descends into a directory that holds them.
