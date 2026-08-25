import 'dart:io';

import 'package:path/path.dart' as p;

/// Locates this package and the repository it lives in, from wherever the
/// tests were started.
///
/// The suite runs from two directories in practice: from the package itself
/// when melos executes it per package, and from the repository root when
/// someone runs `dart test tooling/scaffold`.
final String packageRoot = _find(
  (directory) =>
      p.basename(directory) == 'scaffold' &&
      File(p.join(directory, 'pubspec.yaml')).existsSync(),
  (directory) =>
      Directory(p.join(directory, 'tooling', 'scaffold')).existsSync()
      ? p.join(directory, 'tooling', 'scaffold')
      : null,
);

/// The repository root, which is where arch_check's binary and rule file are.
final String repositoryRoot = p.dirname(p.dirname(packageRoot));

/// arch_check's entrypoint, run as a subprocess by the acceptance test.
final String archCheckBin = p.join(
  repositoryRoot,
  'tooling',
  'arch_check',
  'bin',
  'arch_check.dart',
);

/// arch_check's rule file.
final String archCheckRules = p.join(
  repositoryRoot,
  'tooling',
  'arch_check',
  'rules.yaml',
);

String _find(
  bool Function(String directory) isHere,
  String? Function(String directory) isBelow,
) {
  var directory = Directory.current.absolute.path;
  while (true) {
    if (isHere(directory)) return directory;
    final below = isBelow(directory);
    if (below != null) return below;
    final parent = p.dirname(directory);
    if (parent == directory) {
      throw StateError(
        'Could not locate the scaffold package from ${Directory.current.path}.',
      );
    }
    directory = parent;
  }
}
