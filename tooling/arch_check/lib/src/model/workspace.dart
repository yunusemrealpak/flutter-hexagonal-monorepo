import 'workspace_package.dart';

/// Every package the checker found, plus the root they were found under.
final class Workspace {
  /// Creates a workspace from the packages found under [rootPath].
  Workspace({required this.rootPath, required List<WorkspacePackage> packages})
    : packages = List.unmodifiable(packages),
      _byName = {for (final package in packages) package.name: package};

  /// The absolute, normalised path the packages were discovered under.
  final String rootPath;

  /// Every typed package, ordered by path.
  final List<WorkspacePackage> packages;
  final Map<String, WorkspacePackage> _byName;

  /// The workspace package with this name, or `null` when the name belongs to
  /// a third-party package.
  ///
  /// A name that is not here is treated as third party rather than as an
  /// error, and pub is what makes that safe: a member depending on a product
  /// package that does not exist fails to resolve long before this checker
  /// runs.
  WorkspacePackage? byName(String name) => _byName[name];
}
