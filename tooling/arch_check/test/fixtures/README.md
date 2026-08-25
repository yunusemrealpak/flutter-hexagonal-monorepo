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
| `broken_feature` | **The one to read first.** A plausible `billing` feature written by someone who has not read the constitution, with the clean packages around it that make its mistakes measurable. 28 violations across 18 codes, most of them consequences of two or three decisions. See below. |

## `broken_feature`, and how to read it

```bash
dart run tooling/arch_check/bin/arch_check.dart \
  --root=tooling/arch_check/test/fixtures/broken_feature
```

Every other fixture isolates a section so the test can measure it. This one does the opposite: it is one feature, written the way features get written under deadline, and it shows what the report looks like when a real change goes wrong.

| Package | What its author did | What the report says |
|---|---|---|
| `billing_api` | Put the DTO next to the entity, wired `json_serializable` where the DTO was, kept an `HttpBillingRepository` stub beside the port it implements, re-exported `core_kernel` "because callers need `Result` anyway", and reached for `@immutable` | `serialization_in_api` ×3, `implementation_in_api`, `barrel_leak`, `flutter_in_pure_dart`, `forbidden_dependency` |
| `billing_application` | Constructed the adapter instead of taking it, read the ambient clock, configured the transport in the use case, resolved a collaborator through a locator, and printed a diagnostic | `forbidden_dependency` ×3, `ambient_clock`, `ambient_print`, `technology_in_domain`, `locator_outside_app`, `flutter_in_pure_dart` |
| `billing_infrastructure` | Imported a type that was not exported from the barrel, threw on bad input from a method returning `Result`, used another feature's concept, and committed generated output with no `build.yaml` | `deep_import`, `exception_at_port_boundary`, `forbidden_dependency`, `unpinned_builders` |
| `billing_presentation` | Constructed the use case in the widget, named the barrel after the feature, and skipped `resolution: workspace` | `forbidden_dependency`, `missing_barrel`, `stray_lib_file`, `unregistered_package` |
| `billing_testing` | Added the package last, never registered it, and let the fake invent identifiers | `unregistered_package`, `ambient_random` |
| `shipments_application` | Called billing's use case directly, while billing called back | `forbidden_dependency`, and the `dependency_cycle` that closes |
| `packages/shared/billing_shared` | "Both features need this, so it goes somewhere in the middle" | `unknown_package_type` |

Two things are worth noticing in the output.

**One decision produces several violations.** Depending on `billing_infrastructure` from `billing_application` is a single line in a pubspec; it shows up as a forbidden edge, and it is what let the use case construct an adapter, which is what pulled `dio` into the domain. The report reads as a list of rules, but the fix is usually three or four lines in one file.

**The same code carries different advice.** `forbidden_dependency` fires seven times here, and the remedy is not the same sentence each time: a feature reaching past another feature's contract is told which `_api` to use instead, while an adapter reaching for a foreign `_api` is already using it — its crossing belongs to a use case, and the message says so.

### The shared package, and what is reported about it

`billing_application` depends on `billing_shared`, and both halves of that are reported: the package itself as `unknown_package_type`, and the edge into it as `forbidden_dependency`.

The second half used to be missing, and this fixture is what found it. A package that resolves to no type is left out of the graph, so a dependency into it looked exactly like a dependency on a package from pub — which meant the classic mistake showed up once, on the package everybody agreed to create, while the packages that then depended on it looked clean. The loader now keeps untyped names addressable for exactly this reason.

What the checker still cannot do is judge the *fix*. Section 8 of the dependency rules says it: nothing here can tell you that the right answer is mutual contracts rather than a package in the middle. It can only make the package in the middle impossible to ignore.

## Rules for adding one

1. **One fixture per rule family, not per rule.** A fixture that breaks one rule in isolation says nothing about interference between rules; a fixture that breaks a whole section at once says what the section costs when it is ignored.
2. **Assert the exact multiset of codes**, not merely that the expected one is present. Containment would let a rule start firing everywhere and still pass, and a checker that cries wolf is worked around within a week.
3. **Keep `clean` clean.** When a new rule is added, run it against `clean` first. If it fires there, the rule is wrong before the fixture is written.
4. **Write the fixture in the same commit as the rule.** §9 of `docs/DEPENDENCY_RULES.md`: a rule with no fixture is a rule that will silently stop working.

## Why these are excluded from analysis

The root `analysis_options.yaml` excludes `tooling/*/test/fixtures/**`. These packages have no pub resolution and are deliberately broken, so every `package:` URI in them is unresolvable and `dart analyze` would report dozens of errors that mean nothing. The exclusion is scoped to fixture directories under `tooling/` so that no product source can ever fall inside it.

`arch_check` skips them for a different reason and by a different mechanism: `test` is on the discovery skip list in `rules.yaml`, so a run against the real workspace never descends into a directory that holds them.
