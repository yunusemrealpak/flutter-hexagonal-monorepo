import 'model/test_package.dart';

/// Which packages a set of changed files can break.
///
/// Two steps. **Map paths to packages**: a file under a package's directory
/// belongs to that package, longest prefix wins. **Walk the dependents**: if
/// `core_kernel` changed, everything that depends on it — transitively, and
/// through `dev_dependencies:` as well — can break.
///
/// Dev edges count here where they did not count in the dependency graph. A
/// change to `routing_testing` cannot break anybody's build and can certainly
/// break their suite, and a test runner that ignored that would go green on
/// a broken contract kit.
final class AffectedPackages {
  /// Creates the calculator over [packages].
  AffectedPackages(this.packages)
    : _dependents = _invert(packages),
      _byPath = _sortedByPathLength(packages);

  /// Every package in the workspace.
  final List<TestPackage> packages;

  final Map<String, Set<String>> _dependents;
  final List<TestPackage> _byPath;

  /// The packages [changedPaths] touch, before dependents are walked.
  ///
  /// A path outside every package — `.github/workflows/pr.yml`, `README.md`,
  /// the root pubspec — belongs to no package and is reported by
  /// [touchesEverything] instead.
  Set<String> directlyChanged(Iterable<String> changedPaths) {
    final changed = <String>{};
    for (final path in changedPaths) {
      final normalised = path.replaceAll(r'\', '/');
      for (final package in _byPath) {
        if (normalised == package.relativePath ||
            normalised.startsWith('${package.relativePath}/')) {
          changed.add(package.name);
          break;
        }
      }
    }
    return changed;
  }

  /// Whether one of [changedPaths] is a file no package owns and everything
  /// depends on.
  ///
  /// The root pubspec pins every version in the workspace; the lockfile is the
  /// resolution itself; the analysis options decide whether anything compiles
  /// cleanly. A change to one of them can break any package, and a runner that
  /// answered "nothing is affected" would be wrong in the most expensive
  /// direction.
  bool touchesEverything(Iterable<String> changedPaths) {
    const global = {
      'pubspec.yaml',
      'pubspec.lock',
      'analysis_options.yaml',
      'dart_test.yaml',
    };
    for (final path in changedPaths) {
      final normalised = path.replaceAll(r'\', '/');
      if (global.contains(normalised)) return true;
    }
    return false;
  }

  /// [seeds] plus everything that depends on them, transitively.
  Set<String> withDependents(Set<String> seeds) {
    final reached = <String>{...seeds};
    final queue = [...seeds];
    while (queue.isNotEmpty) {
      final name = queue.removeLast();
      for (final dependent in _dependents[name] ?? const <String>{}) {
        if (reached.add(dependent)) queue.add(dependent);
      }
    }
    return reached;
  }

  /// The packages to run for [changedPaths], in workspace order.
  ///
  /// Packages with no tests are left out here rather than by the caller: they
  /// still have to be walked as dependencies, and they have nothing to run.
  List<TestPackage> forChanges(Iterable<String> changedPaths) {
    final paths = changedPaths.toList();
    if (touchesEverything(paths)) {
      return [
        for (final package in packages)
          if (package.hasTests) package,
      ];
    }
    final selected = withDependents(directlyChanged(paths));
    return [
      for (final package in packages)
        if (package.hasTests && selected.contains(package.name)) package,
    ];
  }

  static Map<String, Set<String>> _invert(List<TestPackage> packages) {
    final dependents = <String, Set<String>>{};
    for (final package in packages) {
      for (final dependency in package.allDependencies) {
        dependents.putIfAbsent(dependency, () => <String>{}).add(package.name);
      }
    }
    return dependents;
  }

  /// Longest path first, so `packages/features/routing/routing_api` wins over
  /// a package that happened to live at `packages/features/routing`.
  static List<TestPackage> _sortedByPathLength(List<TestPackage> packages) =>
      [...packages]..sort(
        (a, b) => b.relativePath.length.compareTo(a.relativePath.length),
      );
}
