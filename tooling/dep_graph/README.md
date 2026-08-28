# dep_graph

Renders the workspace's dependency graph into [`docs/dependency-graph.md`](../../docs/dependency-graph.md), colour-coded by package type, and fails when the graph has a cycle.

```bash
dart run tooling/dep_graph/bin/dep_graph.dart                 # rewrite the file
dart run tooling/dep_graph/bin/dep_graph.dart --check         # fail if stale
dart run tooling/dep_graph/bin/dep_graph.dart --stdout --format=dot
dart run melos run graph                                      # what a commit runs
dart run melos run graph:check                                # what CI runs
```

Exit codes: **0** clean, **1** a cycle or a stale file, **64** the tool could not run. The third is separate for the same reason it is in `arch_check` — a tool that exits 1 both for "the architecture is broken" and for "I could not read my own inputs" teaches CI to treat the second as the first.

## What it draws, and what it deliberately does not

| Output | Scope | Why |
|---|---|---|
| Mermaid, type graph | one node per package *type* | the diagram to hold against §2 of the dependency rules |
| Mermaid, payments ↔ shipments | eleven packages | scenario 1: two features that need each other, and no cycle |
| Mermaid, `routing` | one full split plus what it touches | `_application` and `_infrastructure` never meeting |
| Graphviz DOT | all 74 packages | `dot` ranks a DAG so every edge points one way; Mermaid draws what it is given |

**Never the whole workspace in Mermaid.** Seventy-four nodes and four hundred edges render as a wall, and a diagram nobody can read is a diagram nobody checks against the code.

**Third-party dependencies are not edges.** They are a fact about a package rather than about the shape of the repository. **Dev-dependency edges are dashed**, because a `_testing` package reaches its consumers through `dev_dependencies:` and drawing that solid would say a feature's fakes ship in the product build.

**Nothing is time-stamped.** The file is generated and committed (§4.3 of CLAUDE.md), so a run that changed one byte per invocation would fail the staleness gate on every commit and teach everybody to ignore it.

## What it may depend on

`args`, `path`, `yaml`, and nothing in `packages/`, `apps/` or `tooling/`. §2 gives a tooling package an empty allow-list, which is why the workspace walk here is a second copy of the one in `arch_check` rather than an import.

What is *not* duplicated is the decision about a package's type. That comes from **`tooling/arch_check/rules.yaml`, read as data at a path** — one source of truth for "what type is this package", and no edge in the graph this tool exists to draw. A diagram that classified a package differently from the checker would be a diagram that lies.

## What must never live in it

- A rule about which edges are *allowed*. That is `arch_check`'s, and a second opinion about it is how two tools start disagreeing in a pull request.
- A hand-edited section in the output. The file says so at the top; anything a human wants to say about the graph belongs in `docs/ARCHITECTURE.md`.
- A timestamp, a commit hash, or anything else that changes without the graph changing.

## Its own tests

`test/fixtures/` holds two mini workspaces — one clean, one with `alpha_api` and `beta_api` depending on each other — each with its own `rules.yaml`, so the renderer is exercised without the real workspace's size. One test runs against the **real** repository and asserts it has no cycle: that is success criterion 4 of the specification, checked rather than described.
