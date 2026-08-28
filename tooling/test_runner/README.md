# test_runner

Decides which packages a change can break, runs their tests with the runner each one needs, skips whatever has not moved since it last passed, and reports what it did.

```bash
dart run tooling/test_runner/bin/test_runner.dart                       # everything
dart run tooling/test_runner/bin/test_runner.dart --affected            # what a diff can break
dart run tooling/test_runner/bin/test_runner.dart --affected --list     # just the selection
dart run tooling/test_runner/bin/test_runner.dart --bucket=3 --total=10 # one CI machine
dart run tooling/test_runner/bin/test_runner.dart --bundle --junit=build/junit.xml
dart run melos run test:affected                                        # what the hook runs
```

Exit codes: **0** everything selected passed, **1** a suite failed, **64** the runner could not run.

## The six capabilities, and the decision inside each

| | What it does | The decision worth reading |
|---|---|---|
| **Affected** | `--affected --base=origin/main` | Four git questions, not one: committed, staged, unstaged, untracked. A pre-push hook that only asked the first would pass on work that has not been committed — the one moment it exists to catch. A diff git cannot answer runs **everything**, because a selective run built on a failed diff silently covers nothing. |
| **Runner selection** | `dart test` or `flutter test` | Read from the pubspec's `sdk: flutter`, never guessed from the path — a `platform/*` package and an `_api` package live at the same depth. `-j` goes to `dart test` only; `flutter test` schedules against its own engine and overriding it makes a widget suite slower. |
| **Bundling** | `--bundle` | One entrypoint per package, so the suite compiles and starts once instead of once per file. A flag rather than the default because a library-level `@Tags`/`@TestOn` belongs to the file that carries it, and a bundle is a different file — so any run that filters by tag has to stay unbundled. |
| **Hash-skip** | on by default, `--no-cache` to disable | sha256 over the package's sources **plus the sources of everything it depends on**, plus `pubspec.lock`. A hash of the package alone would skip `routing_application` after a change to `core_kernel`, which is the one case the cache exists to get right. Generated files count: §4.3 puts them in the repository, so they are source. |
| **Bucketing** | `--bucket i --total n` | Longest-processing-time first against `.cache/timings.json`. Splitting by *count* puts one widget suite next to nine `_api` packages and leaves nine machines idle. Ties break on name, so a flaky failure can be reproduced on the machine that saw it. |
| **Reporting** | `--junit=<path>` and a summary | One test case per **package**, not per test. The runner reads exit codes; parsing two machine reporters into per-test cases would make this a second, worse copy of two tools that already exist. A skipped package is a `<skipped/>` case rather than an absent one, so a warm cache does not look like a shrinking suite. |

## What it may depend on

`args`, `crypto`, `path`, `yaml`, and nothing in `packages/`, `apps/` or `tooling/` — §2 gives a tooling package an empty allow-list.

It enumerates the workspace from the **root pubspec's `workspace:` list**, not by walking directories. That list is what pub resolves against, so a package missing from it is a package no test run should pretend to cover — and a directory holding an unregistered pubspec is exactly what `arch_check` reports separately.

## What must never live in it

- A test framework. It launches `dart test` and `flutter test`; the day it starts interpreting their output it has become a third one.
- A rule about which packages *may* depend on which. That is `arch_check`'s.
- Anything that makes a run non-deterministic. Bucketing, hashing and ordering are all stable for the same input, because the alternative is a failure nobody can reproduce.

## State it keeps

`.cache/test_hashes.json` and `.cache/timings.json`, both gitignored. A skip decision and a measured duration are facts about one machine's history, not about the repository. CI restores them as a cache entry and stores the timings as an artifact.

## Its own tests

`test/fixtures/mini/` is a five-package workspace — a kernel, a contract, a use-case package that dev-depends on the kernel, a Flutter package, and one package with no tests at all. Every subprocess goes through a `CommandRunner` the tests fake, because every decision this tool makes is decided by what a subprocess said, and a test that had to launch `git` and `flutter` to check the decision would not be a test of the decision.
