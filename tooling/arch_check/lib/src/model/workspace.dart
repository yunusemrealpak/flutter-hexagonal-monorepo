import 'workspace_package.dart';

/// Every package the checker found, plus the root they were found under.
final class Workspace {
  /// Creates a workspace from the packages found under [rootPath].
  ///
  /// [untypedPackages] names the packages that were found on disk and whose
  /// path and name resolved to no type. They are kept apart from [packages]
  /// because no rule can be applied to them — and kept at all because an edge
  /// into one still has to be reported.
  Workspace({
    required this.rootPath,
    required List<WorkspacePackage> packages,
    Set<String> untypedPackages = const {},
  }) : packages = List.unmodifiable(packages),
       untypedPackages = Set.unmodifiable(untypedPackages),
       _byName = {for (final package in packages) package.name: package};

  /// The absolute, normalised path the packages were discovered under.
  final String rootPath;

  /// Every typed package, ordered by path.
  final List<WorkspacePackage> packages;

  /// The names of packages that were discovered but resolved to no type.
  ///
  /// Each of them is already reported as `unknown_package_type`. This set
  /// exists so that the edges *into* them are reported too: without it a
  /// package the constitution cannot reason about is indistinguishable, at
  /// every call site, from a package on pub.
  final Set<String> untypedPackages;

  final Map<String, WorkspacePackage> _byName;

  /// The workspace package with this name, or `null` when the name belongs to
  /// a third-party package or to an untyped one.
  ///
  /// A name that is neither here nor in [untypedPackages] is treated as third
  /// party rather than as an error, and pub is what makes that safe: a member
  /// depending on a product package that does not exist fails to resolve long
  /// before this checker runs.
  WorkspacePackage? byName(String name) => _byName[name];

  /// Whether [name] belongs to a package that was found on disk and could not
  /// be typed.
  bool isUntyped(String name) => untypedPackages.contains(name);
}
