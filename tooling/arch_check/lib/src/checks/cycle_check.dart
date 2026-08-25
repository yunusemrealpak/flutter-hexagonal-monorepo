import '../model/violation.dart';
import '../model/workspace_package.dart';
import 'check.dart';

/// S7: the dependency graph is acyclic.
///
/// Only `dependencies:` forms an edge. A cycle through `dev_dependencies:` is
/// legal for pub and architecturally uninteresting — a package's test harness
/// depending back on it says nothing about what ships.
///
/// Tarjan's algorithm, iterative rather than recursive: the graph is small, but
/// a checker that overflows its stack on a pathological workspace fails in the
/// one case it exists for.
final class CycleCheck implements Check {
  /// Creates the cycle check.
  const CycleCheck();

  @override
  String get name => 'dependency cycles (rule S7)';

  @override
  Iterable<Violation> run(CheckContext context) sync* {
    final packages = context.workspace.packages;
    final edges = <String, List<String>>{
      for (final package in packages)
        package.name: [
          for (final dependency in package.dependencies)
            if (context.workspace.byName(dependency.name) != null)
              dependency.name,
        ],
    };

    for (final component in _stronglyConnected(edges)) {
      // A component of one is only a cycle when the package depends on itself,
      // which pub rejects anyway; keeping the check costs nothing and means
      // this reports every cycle the graph can express.
      final isCycle =
          component.length > 1 ||
          (edges[component.single]?.contains(component.single) ?? false);
      if (!isCycle) continue;

      final ordered = [...component]..sort();
      final anchor = context.workspace.byName(ordered.first)!;
      yield Violation(
        code: 'dependency_cycle',
        location: ViolationLocation(package: anchor.relativePath),
        what: 'these packages form a cycle: ${_render(ordered, edges)}',
        remedy: context.rules.remedyFor('dependency_cycle'),
      );
    }
  }

  /// Renders the cycle as a path a reader can follow, starting at the
  /// alphabetically first package so that the same cycle prints the same way
  /// on every run.
  String _render(List<String> component, Map<String, List<String>> edges) {
    final members = component.toSet();
    final path = <String>[component.first];
    var current = component.first;
    while (true) {
      final next =
          (edges[current] ?? const <String>[])
              .where(members.contains)
              .where((name) => name != current || members.length == 1)
              .toList()
            ..sort();
      final step = next.firstWhere(
        (name) => !path.contains(name),
        orElse: () => component.first,
      );
      path.add(step);
      if (step == component.first) return path.join(' -> ');
      current = step;
    }
  }

  List<List<String>> _stronglyConnected(Map<String, List<String>> edges) {
    final index = <String, int>{};
    final lowLink = <String, int>{};
    final onStack = <String>{};
    final stack = <String>[];
    final components = <List<String>>[];
    var counter = 0;

    for (final root in edges.keys) {
      if (index.containsKey(root)) continue;
      // Each frame is a node plus how many of its successors have been visited.
      final work = <({String node, int next})>[(node: root, next: 0)];
      index[root] = lowLink[root] = counter++;
      stack.add(root);
      onStack.add(root);

      while (work.isNotEmpty) {
        final frame = work.removeLast();
        final successors = edges[frame.node] ?? const <String>[];
        if (frame.next < successors.length) {
          work.add((node: frame.node, next: frame.next + 1));
          final successor = successors[frame.next];
          if (!index.containsKey(successor)) {
            index[successor] = lowLink[successor] = counter++;
            stack.add(successor);
            onStack.add(successor);
            work.add((node: successor, next: 0));
          } else if (onStack.contains(successor)) {
            lowLink[frame.node] = _min(
              lowLink[frame.node]!,
              index[successor]!,
            );
          }
          continue;
        }

        if (lowLink[frame.node] == index[frame.node]) {
          final component = <String>[];
          String member;
          do {
            member = stack.removeLast();
            onStack.remove(member);
            component.add(member);
          } while (member != frame.node);
          components.add(component);
        }
        if (work.isNotEmpty) {
          final parent = work.last.node;
          lowLink[parent] = _min(lowLink[parent]!, lowLink[frame.node]!);
        }
      }
    }
    return components;
  }

  int _min(int a, int b) => a < b ? a : b;
}

/// Exposed for the graph the reporter prints in verbose mode.
List<String> dependencyNames(WorkspacePackage package) =>
    package.dependencies.map((dependency) => dependency.name).toList();
