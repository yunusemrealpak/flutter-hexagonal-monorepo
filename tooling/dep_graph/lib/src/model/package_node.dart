/// One package in the graph.
///
/// Deliberately thinner than `arch_check`'s equivalent: a renderer needs a
/// name, a place, a type and a list of edges, and nothing else. Everything the
/// checker reads — `build.yaml`, workspace registration, SDK constraints — is
/// its business rather than this tool's.
final class PackageNode {
  /// Creates a node.
  const PackageNode({
    required this.name,
    required this.relativePath,
    required this.typeId,
    required this.owningFeature,
    required this.dependencies,
    required this.devDependencies,
  });

  /// The `name:` of the pubspec, which is what an edge names.
  final String name;

  /// Posix path from the workspace root, e.g. `packages/core/core_ports`.
  final String relativePath;

  /// The type identifier from `rules.yaml`, e.g. `feature_api`. `null` when
  /// the package's path and name resolve to no type, or to more than one.
  ///
  /// A tool that draws the graph reports an unknown type and keeps drawing.
  /// `arch_check` is what turns it into a violation.
  final String? typeId;

  /// For a feature package, the directory under `packages/features/`.
  final String? owningFeature;

  /// Every name in the pubspec's `dependencies:` block, third party included.
  final List<String> dependencies;

  /// Every name in `dev_dependencies:`.
  ///
  /// Kept apart because §2 governs one block and not the other, and because a
  /// `_testing` package reaches its consumers through this one. Drawing them
  /// as the same edge would say a feature's fakes ship in its product build.
  final List<String> devDependencies;

  @override
  String toString() => '$name (${typeId ?? 'untyped'})';
}
