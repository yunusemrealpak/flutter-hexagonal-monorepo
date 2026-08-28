## What this changes

<!-- One paragraph. What moved, and what it is for. -->

## Why this shape

<!--
The section that matters most in this repository. Which architectural decision
does the change reflect, and which alternative did you reject?

If the change adds an edge to a pubspec, say which row of §2 in
docs/DEPENDENCY_RULES.md allows it. If it adds a port, say why it is declared
where it is declared (§2.2). If it splits or widens a driving port, say which
audience each half is for (§2.3).
-->

## Checks

<!-- CI runs all of these. Tick what you ran locally; a box you did not run is
     not a failure, it is information for the reviewer. -->

- [ ] `dart run melos run gen` — generated files travel in this commit
- [ ] `dart analyze --fatal-infos --fatal-warnings .`
- [ ] `dart run melos run arch:check`
- [ ] `dart run melos run graph:check`
- [ ] `dart run melos run test:affected`

## Packages touched

<!-- The pr workflow comments the affected list. Paste anything surprising
     about it here — a change that reaches more packages than you expected is
     usually telling you something about the graph. -->

## Known gaps

<!-- What this does not do, and what a follow-up would have to. "None" is a
     valid answer; silence is not. -->
