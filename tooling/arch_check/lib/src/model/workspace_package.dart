import 'package:yaml/yaml.dart';

import 'dependency.dart';
import 'package_type.dart';

/// One package on disk, as the checker sees it.
///
/// Everything here is read once, at load time: the pubspec, the build
/// configuration, and the package's position in the tree. Checks work against
/// this snapshot rather than touching the filesystem again, which is what
/// keeps a full run over 75 packages in the low hundreds of milliseconds.
final class WorkspacePackage {
  /// Creates the snapshot the checks work against.
  const WorkspacePackage({
    required this.name,
    required this.directoryName,
    required this.relativePath,
    required this.absolutePath,
    required this.type,
    required this.owningFeature,
    required this.dependencies,
    required this.devDependencies,
    required this.declaresWorkspaceResolution,
    required this.isRegisteredInWorkspace,
    required this.buildConfig,
  });

  /// The `name:` field of the pubspec.
  final String name;

  /// The name of the directory the pubspec sits in. Rule S5 requires the two
  /// to be equal, so they are kept apart until that check has run.
  final String directoryName;

  /// Posix path relative to the workspace root, e.g. `packages/core/core_ports`.
  final String relativePath;

  /// The package directory's absolute path.
  final String absolutePath;

  /// The one type its path and name resolve to.
  final PackageType type;

  /// For a feature package, the directory name under `packages/features/`.
  /// `null` for every other type.
  final String? owningFeature;

  /// The `dependencies:` block, which is what section 2 governs.
  final List<Dependency> dependencies;

  /// The `dev_dependencies:` block, out of scope for section 2 and in scope
  /// for the rule that forbids importing one from `lib/`.
  final List<Dependency> devDependencies;

  /// Whether the pubspec says `resolution: workspace`.
  final bool declaresWorkspaceResolution;

  /// Whether the root pubspec's `workspace:` list names this package's path.
  final bool isRegisteredInWorkspace;

  /// The parsed `build.yaml`, or `null` when the package has none. A package
  /// with no generated files is expected to have none — that is the cheapest
  /// configuration, not a missing one.
  final YamlMap? buildConfig;

  /// The `_api` package of this package's own feature, e.g. `shipments_api`.
  /// `null` for a non-feature package.
  String? get ownApiName =>
      owningFeature == null ? null : '${owningFeature}_api';

  /// Whether the package carries a `build.yaml`.
  bool get hasBuildConfig => buildConfig != null;

  @override
  String toString() => '$name (${type.id}) at $relativePath';
}
