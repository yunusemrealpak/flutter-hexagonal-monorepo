/// Renders the workspace's dependency graph, and fails on a cycle.
///
/// The graph is written to `docs/dependency-graph.md` and committed, so it is
/// reviewable in a pull request and so a moved edge shows up as a diff rather
/// than as a fact somebody has to go and re-derive.
///
/// **It reads `arch_check`'s `rules.yaml` and does not import `arch_check`.**
/// §2 gives a tooling package an empty allow-list, so the workspace walk is a
/// second copy on purpose. What is not copied is the decision about a
/// package's type: that comes from the same rule file, read as data, because a
/// diagram that classified a package differently from the checker would be a
/// diagram that lies.
library;

export 'src/cli.dart' show ExitCodes, runCli;
export 'src/model/dependency_graph.dart';
export 'src/model/package_node.dart';
export 'src/render/document.dart' show GraphDocument;
export 'src/render/dot.dart' show Dot;
export 'src/render/mermaid.dart' show Mermaid;
export 'src/render/palette.dart' show TypeStyle, styleFor, typeStyles;
export 'src/scanner.dart' show WorkspaceScanner;
export 'src/type_matchers.dart' show TypeMatcher, TypeRules;
