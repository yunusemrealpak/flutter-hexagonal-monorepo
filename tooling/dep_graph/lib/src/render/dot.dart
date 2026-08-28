import '../model/dependency_graph.dart';
import 'palette.dart';

/// Renders the complete graph as Graphviz DOT.
///
/// DOT gets the whole workspace where Mermaid gets three views, and the reason
/// is layout: `dot` ranks a directed acyclic graph so that every edge points
/// the same way, which turns seventy-four packages into a readable picture of
/// the rings. Mermaid draws what it is given.
abstract final class Dot {
  /// The whole graph, clustered by the directory packages live under.
  static String render(DependencyGraph graph) {
    final clusters = <String, List<String>>{};
    for (final node in graph.nodes) {
      final style = styleFor(node.typeId);
      final line =
          '    "${node.name}" [fillcolor="${style.fill}", '
          'color="${style.stroke}"];';
      clusters.putIfAbsent(_clusterOf(node.relativePath), () => []).add(line);
    }

    return [
      'digraph peyk {',
      '  rankdir=LR;',
      '  graph [fontname="Helvetica", splines=true, overlap=false];',
      _nodeDefaults,
      '  edge [color="#90a4ae", arrowsize=0.7];',
      '',
      for (final name in clusters.keys.toList()..sort()) ...[
        '  subgraph "cluster_${name.replaceAll('/', '_')}" {',
        '    label="$name";',
        '    style=dotted;',
        '    color="#b0bec5";',
        ...clusters[name]!..sort(),
        '  }',
        '',
      ],
      for (final edge in graph.runtimeEdges)
        '  "${edge.from}" -> "${edge.to}";',
      for (final edge in graph.edges)
        if (edge.isDev) _devEdge(edge),
      '}',
    ].join('\n');
  }

  static const String _nodeDefaults =
      '  node [shape=box, style="filled,rounded", fontname="Helvetica", '
      'fontsize=10];';

  static String _devEdge(GraphEdge edge) =>
      '  "${edge.from}" -> "${edge.to}" [style=dashed, color="#cfd8dc"];';

  /// The directory a package is grouped under, one level below its root.
  ///
  /// `packages/features/routing/routing_api` clusters as
  /// `packages/features/routing`; `tooling/dep_graph` as `tooling`.
  static String _clusterOf(String relativePath) {
    final parts = relativePath.split('/');
    if (parts.length <= 2) return parts.first;
    return parts.take(parts.length - 1).join('/');
  }
}
