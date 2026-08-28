/// One workspace package, as the runner needs to see it.
final class TestPackage {
  /// Creates the record.
  const TestPackage({
    required this.name,
    required this.relativePath,
    required this.absolutePath,
    required this.dependencies,
    required this.devDependencies,
    required this.usesFlutter,
    required this.hasTests,
  });

  /// The pubspec's `name:`, which is what a dependency edge names.
  final String name;

  /// Posix path from the workspace root.
  final String relativePath;

  /// The package directory.
  final String absolutePath;

  /// Workspace-internal names from `dependencies:`.
  final List<String> dependencies;

  /// Workspace-internal names from `dev_dependencies:`.
  ///
  /// These matter here where they did not matter to the graph renderer: a
  /// change to `routing_testing` can break the suite of every package that
  /// consumes its fakes, and that consumption is a dev dependency.
  final List<String> devDependencies;

  /// Whether the pubspec names the Flutter SDK, directly or through a plugin
  /// that pulls it in.
  ///
  /// It decides the runner. `dart test` cannot start a package that binds to
  /// Flutter, and `flutter test` is several seconds slower to start for one
  /// that does not.
  final bool usesFlutter;

  /// Whether the package has a `test/` directory with at least one test file.
  final bool hasTests;

  /// Every internal edge, whichever block it came from.
  List<String> get allDependencies => [...dependencies, ...devDependencies];

  @override
  String toString() => name;
}
