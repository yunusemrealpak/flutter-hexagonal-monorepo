import 'package_node.dart';

/// One directed edge between two workspace packages.
final class GraphEdge {
  /// Creates an edge from [from] to [to].
  const GraphEdge({
    required this.from,
    required this.to,
    required this.isDev,
  });

  /// The depending package's name.
  final String from;

  /// The depended-upon package's name.
  final String to;

  /// Whether the edge comes from `dev_dependencies:` rather than
  /// `dependencies:`.
  final bool isDev;

  @override
  String toString() => '$from -> $to${isDev ? ' (dev)' : ''}';
}

/// The workspace's packages and the edges between them.
///
/// Third-party dependencies are not edges. They are a fact about a package,
/// not about the shape of the repository, and drawing seventy of them would
/// bury the twelve that carry the argument.
final class DependencyGraph {
  /// Builds the graph over [nodes], keeping only edges whose target is itself
  /// a workspace package.
  factory DependencyGraph(List<PackageNode> nodes) {
    final byName = {for (final node in nodes) node.name: node};
    final edges = <GraphEdge>[];
    for (final node in nodes) {
      for (final name in node.dependencies) {
        if (byName.containsKey(name)) {
          edges.add(GraphEdge(from: node.name, to: name, isDev: false));
        }
      }
      for (final name in node.devDependencies) {
        if (byName.containsKey(name)) {
          edges.add(GraphEdge(from: node.name, to: name, isDev: true));
        }
      }
    }
    edges.sort((a, b) {
      final byFrom = a.from.compareTo(b.from);
      return byFrom != 0 ? byFrom : a.to.compareTo(b.to);
    });
    return DependencyGraph._(
      List.unmodifiable(nodes),
      List.unmodifiable(edges),
      byName,
    );
  }

  DependencyGraph._(this.nodes, this.edges, this._byName);

  /// Every package, ordered by path.
  final List<PackageNode> nodes;

  /// Every internal edge, ordered by endpoint names.
  final List<GraphEdge> edges;

  final Map<String, PackageNode> _byName;

  /// The node with this name, or `null` when the name is third party.
  PackageNode? byName(String name) => _byName[name];

  /// Nodes of one type, in path order.
  List<PackageNode> ofType(String typeId) => [
    for (final node in nodes)
      if (node.typeId == typeId) node,
  ];

  /// The runtime edges only — what a build actually compiles.
  ///
  /// This is the graph §2 governs and the graph the cycle rule is about. A
  /// `_testing` package is consumed through `dev_dependencies`, so a cycle
  /// through it would be a cycle in nobody's build.
  List<GraphEdge> get runtimeEdges => [
    for (final edge in edges)
      if (!edge.isDev) edge,
  ];

  /// Every strongly connected component with more than one member, plus every
  /// self-edge, over the runtime edges.
  ///
  /// Tarjan's algorithm, iterative rather than recursive: seventy-odd packages
  /// would not overflow a stack, but a tool that reports a cycle by crashing
  /// on one is a tool nobody keeps in CI.
  List<List<String>> cycles() {
    final adjacency = <String, List<String>>{
      for (final node in nodes) node.name: [],
    };
    for (final edge in runtimeEdges) {
      adjacency[edge.from]!.add(edge.to);
    }

    final index = <String, int>{};
    final lowLink = <String, int>{};
    final onStack = <String>{};
    final stack = <String>[];
    final found = <List<String>>[];
    var counter = 0;

    for (final start in adjacency.keys) {
      if (index.containsKey(start)) continue;

      // Each frame is a node and how far through its neighbours we are.
      final work = <(String, int)>[(start, 0)];
      while (work.isNotEmpty) {
        final (node, resumeAt) = work.removeLast();
        var position = resumeAt;

        if (position == 0) {
          index[node] = counter;
          lowLink[node] = counter;
          counter++;
          stack.add(node);
          onStack.add(node);
        }

        var descended = false;
        final neighbours = adjacency[node]!;
        while (position < neighbours.length) {
          final next = neighbours[position];
          position++;
          if (!index.containsKey(next)) {
            work
              ..add((node, position))
              ..add((next, 0));
            descended = true;
            break;
          }
          if (onStack.contains(next)) {
            lowLink[node] = lowLink[node]! < index[next]!
                ? lowLink[node]!
                : index[next]!;
          }
        }
        if (descended) continue;

        if (lowLink[node] == index[node]) {
          final component = <String>[];
          String member;
          do {
            member = stack.removeLast();
            onStack.remove(member);
            component.add(member);
          } while (member != node);
          if (component.length > 1 || adjacency[node]!.contains(node)) {
            component.sort();
            found.add(component);
          }
        }

        if (work.isNotEmpty) {
          final (parent, _) = work.last;
          lowLink[parent] = lowLink[parent]! < lowLink[node]!
              ? lowLink[parent]!
              : lowLink[node]!;
        }
      }
    }

    found.sort((a, b) => a.first.compareTo(b.first));
    return found;
  }
}
