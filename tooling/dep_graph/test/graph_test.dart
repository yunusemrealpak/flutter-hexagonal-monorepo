@Tags(['unit'])
library;

import 'package:dep_graph/dep_graph.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'support/paths.dart';

DependencyGraph _graph(String name) {
  final root = fixture(name);
  final rules = TypeRules.fromFile(p.join(root, 'rules.yaml'));
  return DependencyGraph(WorkspaceScanner(rules).scan(root));
}

void main() {
  group('the scan', () {
    test('types every package from the rule file it was given', () {
      final graph = _graph('tiny');

      expect(graph.nodes.map((node) => node.name), [
        'core_kernel',
        'alpha_api',
        'alpha_application',
        'beta_api',
      ]);
      expect(graph.byName('alpha_api')!.typeId, 'feature_api');
      expect(graph.byName('alpha_application')!.typeId, 'feature_application');
    });

    test('reads the owning feature from the path, not the name', () {
      final graph = _graph('tiny');

      expect(graph.byName('alpha_api')!.owningFeature, 'alpha');
      expect(graph.byName('core_kernel')!.owningFeature, isNull);
    });

    test('a third-party dependency is not an edge', () {
      // `meta` is in alpha_api's pubspec and is not a workspace package. It is
      // a fact about that package rather than about the shape of the
      // repository, and drawing it would bury the edges that carry an
      // argument.
      final graph = _graph('tiny');

      expect(
        graph.byName('alpha_api')!.dependencies,
        contains('meta'),
      );
      expect(
        graph.edges.where((edge) => edge.to == 'meta'),
        isEmpty,
      );
    });

    test('a dev dependency is an edge, and a different one', () {
      final graph = _graph('tiny');
      final dev = graph.edges.where((edge) => edge.isDev).toList();

      expect(dev, hasLength(1));
      expect(dev.single.from, 'alpha_application');
      expect(dev.single.to, 'beta_api');
      expect(graph.runtimeEdges.any((edge) => edge.isDev), isFalse);
    });
  });

  group('cycles', () {
    test('a graph with none reports none', () {
      expect(_graph('tiny').cycles(), isEmpty);
    });

    test('two packages that need each other are one cycle', () {
      final cycles = _graph('cycle').cycles();

      expect(cycles, hasLength(1));
      expect(cycles.single, ['alpha_api', 'beta_api']);
    });

    test('the real workspace has none', () {
      // Success criterion 4 of the specification, asserted rather than
      // described. It runs against the repository this package lives in, so a
      // change that closes a loop fails here as well as in CI.
      final root = p.dirname(p.dirname(packageRoot));
      final rules = TypeRules.fromFile(
        p.join(root, 'tooling', 'arch_check', 'rules.yaml'),
      );
      final graph = DependencyGraph(WorkspaceScanner(rules).scan(root));

      expect(graph.nodes.length, greaterThan(70));
      expect(graph.cycles(), isEmpty);
    });
  });

  group('rendering', () {
    test('the type graph collapses packages into their types', () {
      final mermaid = Mermaid.typeGraph(_graph('tiny'));

      expect(mermaid, startsWith('graph LR'));
      expect(mermaid, contains('feature_api --> core_kernel'));
      // Two features' contracts pointing at each other is the mutual-_api
      // resolution, and it shows up here as a self-edge on one type.
      expect(mermaid, contains('feature_api --> feature_api'));
      expect(mermaid, contains('classDef feature_api'));
    });

    test('a subgraph draws dev edges dashed', () {
      final mermaid = Mermaid.subgraph(
        _graph('tiny'),
        {'alpha_application', 'beta_api'},
      );

      expect(mermaid, contains('alpha_application -.-> beta_api'));
      expect(mermaid, isNot(contains('alpha_application --> beta_api')));
    });

    test('a feature view pulls in what its packages touch', () {
      final mermaid = Mermaid.feature(_graph('tiny'), 'alpha');

      expect(mermaid, contains('alpha_api['));
      expect(mermaid, contains('beta_api['));
      expect(mermaid, contains('core_kernel['));
    });

    test('DOT clusters by directory and colours by type', () {
      final dot = Dot.render(_graph('tiny'));

      expect(dot, startsWith('digraph peyk {'));
      expect(dot, contains('cluster_packages_features_alpha'));
      expect(dot, contains(styleFor('feature_api').fill));
      expect(dot, contains('"alpha_api" -> "core_kernel";'));
    });

    test('the document carries no timestamp', () {
      // It is generated and committed, so a run that changed one byte per
      // invocation would fail the staleness gate on every commit and teach
      // everybody to ignore it.
      final graph = _graph('tiny');

      expect(GraphDocument.render(graph), GraphDocument.render(graph));
    });
  });
}
