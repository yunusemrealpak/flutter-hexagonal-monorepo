import '../model/dependency_graph.dart';
import '../model/package_node.dart';
import 'palette.dart';

/// Renders Mermaid `graph` blocks.
///
/// **Never the whole workspace at once.** Seventy-four nodes and two hundred
/// edges render as a wall, and a diagram nobody can read is a diagram nobody
/// checks against the code. The complete graph goes out as DOT, which has a
/// layout engine; Mermaid gets the three views that carry an argument.
abstract final class Mermaid {
  /// The constitution as it was actually built: one node per package *type*,
  /// one edge wherever a package of one type depends on a package of another.
  ///
  /// This is the diagram to compare against the table in §2 of the dependency
  /// rules. An edge here that is not in that table is a violation `arch_check`
  /// would already have failed on; an edge in the table that is missing here
  /// is a permission nothing has used yet.
  static String typeGraph(DependencyGraph graph) {
    final seen = <String>{};
    final lines = <String>[];

    for (final edge in graph.runtimeEdges) {
      final from = graph.byName(edge.from)?.typeId;
      final to = graph.byName(edge.to)?.typeId;
      if (from == null || to == null) continue;
      final key = '$from>$to';
      if (!seen.add(key)) continue;
      lines.add('  $from --> $to');
    }
    lines.sort();

    final used = <String>{
      for (final node in graph.nodes)
        if (node.typeId != null) node.typeId!,
    };

    return _block(
      direction: 'LR',
      body: [
        for (final typeId in used.toList()..sort())
          '  $typeId["${styleFor(typeId).label}"]',
        '',
        ...lines,
      ],
      classes: used,
      assignments: {for (final typeId in used) typeId: typeId},
    );
  }

  /// One feature's packages, plus every workspace package they touch.
  ///
  /// Dev-dependency edges are dashed. A `_testing` package reaches its
  /// consumers through `dev_dependencies:`, and drawing that as a solid edge
  /// would say a feature's fakes ship in the product build.
  static String feature(DependencyGraph graph, String featureName) {
    final members = [
      for (final node in graph.nodes)
        if (node.owningFeature == featureName) node,
    ];
    final names = {for (final node in members) node.name};
    final reachable = {
      ...names,
      for (final edge in graph.edges)
        if (names.contains(edge.from)) edge.to,
      for (final edge in graph.edges)
        if (names.contains(edge.to)) edge.from,
    };
    return subgraph(graph, reachable);
  }

  /// The packages named in [names], and every edge between them.
  static String subgraph(DependencyGraph graph, Set<String> names) {
    final nodes = [
      for (final node in graph.nodes)
        if (names.contains(node.name)) node,
    ];
    final used = <String>{
      for (final node in nodes)
        if (node.typeId != null) node.typeId!,
    };

    return _block(
      direction: 'LR',
      body: [
        for (final node in nodes) '  ${node.name}["${node.name}"]',
        '',
        for (final edge in graph.edges)
          if (names.contains(edge.from) && names.contains(edge.to)) _edge(edge),
      ],
      classes: used,
      assignments: {
        for (final node in nodes)
          if (node.typeId != null) node.name: node.typeId!,
      },
    );
  }

  /// A dev-dependency edge is dashed; a runtime one is solid.
  static String _edge(GraphEdge edge) => edge.isDev
      ? '  ${edge.from} -.-> ${edge.to}'
      : '  ${edge.from} --> ${edge.to}';

  static String _classDef(String typeId) {
    final style = styleFor(typeId);
    return '  classDef $typeId '
        'fill:${style.fill},stroke:${style.stroke},color:#111827';
  }

  static String _block({
    required String direction,
    required List<String> body,
    required Set<String> classes,
    required Map<String, String> assignments,
  }) {
    final byClass = <String, List<String>>{};
    assignments.forEach((node, typeId) {
      byClass.putIfAbsent(typeId, () => []).add(node);
    });

    return [
      'graph $direction',
      ...body,
      '',
      for (final typeId in classes.toList()..sort()) _classDef(typeId),
      for (final typeId in byClass.keys.toList()..sort())
        '  class ${(byClass[typeId]!..sort()).join(',')} $typeId',
    ].join('\n');
  }
}

/// Everything a feature's own packages depend on, for a caption.
List<PackageNode> membersOf(DependencyGraph graph, String featureName) => [
  for (final node in graph.nodes)
    if (node.owningFeature == featureName) node,
];
