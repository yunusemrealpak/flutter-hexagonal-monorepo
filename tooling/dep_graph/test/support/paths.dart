import 'dart:io';

import 'package:path/path.dart' as p;

/// Locates this package and its fixtures from wherever the tests were started.
///
/// The suite runs from two directories in practice: from the package itself
/// when melos executes it per package, and from the workspace root when
/// somebody runs `dart test tooling/dep_graph`. Both resolve the same way —
/// walk up until the directory named `dep_graph` with a pubspec is found.
final String packageRoot = _findPackageRoot();

/// The directory holding the mini workspaces the tests render.
final String fixturesRoot = p.join(packageRoot, 'test', 'fixtures');

/// The path of one fixture workspace.
String fixture(String name) => p.join(fixturesRoot, name);

String _findPackageRoot() {
  var directory = Directory.current.absolute;
  while (true) {
    if (p.basename(directory.path) == 'dep_graph' &&
        File(p.join(directory.path, 'pubspec.yaml')).existsSync()) {
      return directory.path;
    }
    final nested = p.join(directory.path, 'tooling', 'dep_graph');
    if (File(p.join(nested, 'pubspec.yaml')).existsSync()) return nested;
    final parent = directory.parent;
    if (parent.path == directory.path) {
      throw StateError(
        'Could not locate the dep_graph package from '
        '${Directory.current.path}.',
      );
    }
    directory = parent;
  }
}
