# CI and CD

Which gate lives in which job, and why it lives there rather than somewhere cheaper or somewhere later.

The whole pipeline is four GitHub workflows, one Codemagic config, three Fastlane lanes and one git hook file. Nothing in it is aspirational except the two files that say so at the top.

---

## 1. The four places a check can live

| | Cost per run | Fails at | Good for |
|---|---|---|---|
| **pre-commit** | must be under a second or two | dozens of times a day | formatting, analysis of staged files, the constitution |
| **pre-push** | seconds to a minute | a few times a day | staleness gates, affected tests |
| **pull request** | minutes | once per branch, repeatedly | everything a reviewer needs to trust the diff |
| **merge queue / nightly** | tens of minutes | once per merge, once per day | the full suite, the things a selective run hides |

The rule that places every check: **the earliest gate that can afford it.** A check that runs later than it could wastes somebody's afternoon; a check that runs earlier than it can afford teaches everybody to skip the hook.

---

## 2. `lefthook.yml` — the two local gates

**pre-commit** runs the formatter over the staged files (and re-stages them, so a formatting-only difference never becomes a second commit), the analyzer over those same files, and `arch_check` over the whole workspace.

`arch_check` is on pre-commit and not pre-push for a specific reason: finding out at push time that a commit you already made breaks the constitution is a bad trade — the commit is written, the message is written, and the fix now needs an amend or a second commit. It is affordable because the `arch:check` script runs a compiled snapshot rather than `dart run`, which costs tens of milliseconds instead of four seconds.

The analyzer is scoped to staged files, and that is the known gap: a half-migrated package can be staged while its fix is not, and the hook passes on a workspace that does not compile. **Run `dart analyze --fatal-infos --fatal-warnings .` over the workspace before opening a phase pull request.** Phase 7 hit this and it is written down rather than papered over.

**pre-push** runs the two staleness gates — `gen:check` and `graph:check` — the constitution again, and the affected tests. Codegen is here rather than on pre-commit because running `build_runner` on every commit taxes every commit for a mistake that only becomes expensive once it reaches CI, and pre-push is the last point where catching it still costs nothing.

`arch_check` runs in both, and the duplication is deliberate: the `skip:` block turns every hook off during a merge or a rebase, so a merge commit combining two individually clean branches has never been checked by pre-commit. Pre-push is the last local gate that sees it.

---

## 3. `pr.yml` — ordered so the cheapest failure comes first

```
checkout (fetch-depth 0) → fetch origin/main → Flutter 3.47.1 → restore build cache
  → pub get → format:check → gen:check → analyze → arch:check → graph:check
  → affected list → affected tests → goldens (conditional) → JUnit → PR comment
```

**`fetch-depth: 0` and then an explicit `git fetch origin main`.** These are two different things and both are needed. `actions/checkout` gives you the history of the ref it checked out; `origin/main` as a *ref* still has to be asked for. Both `melos run gen` (whose package filter is `diff: origin/main`) and `test_runner --affected` name it directly, and `test_runner` falls back to running everything when the diff fails — so getting this wrong is silent and expensive rather than loud.

**`gen:check` before the analyzer.** A stale generated file usually produces analyzer errors, and "run `melos run gen`" is a more useful message than forty type errors in a file nobody wrote.

**`graph:check` alongside `arch:check`.** They overlap on cycles and disagree on nothing: `arch_check` finds a cycle in the workspace, `dep_graph` additionally fails when the committed graph no longer matches the pubspecs. The second is a staleness gate of exactly the same kind as `gen:check`.

**Coverage is off here.** It costs roughly a third of the run and nothing on a pull request reads it. Coverage is merged nightly.

**The affected list is posted as a pull-request comment** with `--edit-last --create-if-none`, so a branch accumulates one comment rather than one per push. It is the most useful thing CI can tell a reviewer: a change that reaches more packages than the author expected is the graph saying something about blast radius.

**Goldens are conditional** on the affected list mentioning `design_system` or a `_presentation` package. No test carries the `golden` tag yet; the step is the mechanism, gated in advance on the packages that can break it.

**And the step selects files, not packages.** `flutter test --tags golden` exits 79 — *No tests ran* — in a package that carries no such test, which is every package today. The first run of this workflow ran it across the workspace and collected seventy-five failures for a suite that does not exist yet. The step now greps for the tag, runs only where it is found, and says so and stops when it is found nowhere. The general form of the mistake is worth naming: **a gate written before the thing it gates has to have a defined answer for the empty case**, and "red" is not it.

---

## 4. `main.yml` — the merge queue, and why not `push`

Triggered by `merge_group`, because the combination worth testing is the one that only exists once two independently green branches are put together — and that combination exists **in the queue, before the merge**, where it can still be rejected. A `push: main` trigger tests it after it is already everybody's problem. The push trigger is kept as a fallback for a disabled queue and for manual re-runs.

Ten buckets, with three decisions in them:

**`fail-fast: false`.** One bucket failing is a real failure of that bucket; the other nine still report, so "one flake" stays distinguishable from "everything is broken".

**`--no-cache`.** The hash-skip cache is a developer's convenience. On the way into `main`, every package runs — "it passed on somebody's laptop under the same hash" is not the guarantee this job exists to give.

**`--bundle`.** Nothing is filtered by tag here, which is the condition under which bundling is safe (a library-level `@Tags` belongs to its own file, and a bundle is a different file). One compilation per package instead of one per file.

A second job merges every bucket's `timings.json` into one artifact. Without it each machine assumes the default cost for every package, which degrades bucketing into a split by count — one widget suite next to nine `_api` packages, and nine machines idle.

---

## 5. `nightly.yml` — the four things a selective CI hides

**A full regeneration from a deleted build cache.** `melos run gen` on a pull request regenerates the *changed* packages and trusts build_runner's incremental state for the rest. That state can be wrong. `rm -rf .dart_tool/build && melos run gen:all` is the only thing that catches a generator output which drifted from its source without either being touched.

**The whole suite with no tag exclusions.** Goldens and integration tests run here. They are out of `pr` because they are slow and, for goldens, because a font or renderer difference makes them fail for reasons a pull request cannot act on.

**Merged coverage.** `flutter test --coverage` writes lcov directly; `dart test --coverage` writes the VM's JSON and needs `coverage:format_coverage` after it. The merge is a concatenation, not a merge tool — lcov records are per file and every package reports on its own `lib/`, so no file appears twice.

**`pub outdated`, reported and never applied.** A workspace resolves against one dependency solution, so a version bump is a decision about 75 packages at once and belongs in a pull request somebody read.

A failure opens an issue, because a nightly that fails into a log nobody opens is a nightly that does not exist.

---

## 6. `release.yml` — tags, and the gate that makes them safe

Triggered by `app_*-v*` tags only. Phase tags (`phase-07`) build nothing, and the job reads the app and the version out of the tag's own shape rather than from a second input nobody remembers to update.

The step worth copying is the one before the build: **the constitution, the analyzer, the staleness gate and the full suite run again.** A tag can be pushed at any commit, including one that never went through a pull request. Those four minutes are what remove the only path by which unreviewed code reaches a store.

Symbols are uploaded with a year's retention. An obfuscated release whose symbol map was discarded has crash reports nobody can read, and the map cannot be regenerated after the fact.

---

## 7. `codemagic.yaml` and `fastlane/` — the signed half

GitHub Actions runs the constitution, the analyzer and the tests. It does not hold certificates, provisioning profiles or store credentials. Codemagic does, and the split is the point: **the secrets live in one place, and that place is not a workflow anybody can add a step to in a pull request.**

Per-app `changeset` triggers, so a change to `app_dispatcher` does not rebuild and re-ship the courier app. The changeset for each app includes the whole of `packages/`, which is honest rather than lazy — a change to `core_kernel` really can break a courier's build.

`app_harness` has no workflow. It exists so that every feature can be composed on fakes and the container asserted in milliseconds; giving a test harness a release process would be giving it a meaning it does not have.

Fastlane has three lanes and one rule: **a lane never builds.** Codemagic builds and signs; a lane moves an artefact that already exists. Mixing the two makes a failed upload indistinguishable from a failed compile, and makes "ship the build we already tested" impossible to express. `promote_staged` names no version for the same reason — naming one would let a promotion ship something other than what was tested on the track it came from.

### What has to exist before either can run

Stated at the top of both files, and repeated here because it is the one honest gap in this pipeline:

- `apps/<app>/android/` and `apps/<app>/ios/`. The specification states that iOS and Android builds are explicitly not required of this reference repository, so the native projects were never generated. `flutter create --platforms=android,ios .` inside an app adds them.
- `apps/<app>/config/<flavour>.json`, the values `--dart-define-from-file` reads.
- The signing groups named under `environment.groups`, configured in the Codemagic UI.

Everything else in both files — the triggers, the flavour matrix, the obfuscation flags, the artefact paths, the lane arguments — is real.

---

## 8. Branch protection

`main` is protected: direct pushes are rejected and history is never rewritten. The required status checks are the `pr` workflow's `verify` job and the merge queue's ten buckets.

A phase ends the same way every time (§6 of the constitution): push the phase branch, open a pull request, **merge without squashing** — the in-phase history is the lesson — then tag `phase-NN` and push the tag.

---

## 9. Caching, and the one cache that is not shared

| What | Where | Restored by |
|---|---|---|
| Flutter SDK | `subosito/flutter-action` | `cache: true`, keyed on the pinned version |
| pub packages | same | one resolution for 75 packages, which is what `resolution: workspace` buys |
| build_runner state | `actions/cache`, keyed on `pubspec.lock` + SHA | most of `gen:check`'s cost and none of its value |
| test durations | `actions/upload-artifact` | balanced bucketing on the next run |
| test hashes | **not shared** | `.cache/test_hashes.json` is local only |

The last row is the deliberate one. A hash-skip is a claim that a package's sources have not moved since *this machine* saw them pass. Sharing that claim across machines would mean trusting a run nobody in this pipeline observed, which is exactly the guarantee the merge queue exists to provide. It stays a developer's convenience, and CI passes `--no-cache`.
