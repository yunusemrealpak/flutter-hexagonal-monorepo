import 'dart:io';

import 'package:path/path.dart' as p;

/// Locates this package and its fixtures from wherever the tests were started.
///
/// The suite runs from two directories in practice: from the package itself
/// when melos executes it per package, and from the workspace root when
/// someone runs `dart test tooling/arch_check`. Both resolve the same way here
/// — walk up until the directory holding `rules.yaml` is found — so no test
/// has to know which of the two it is in.
final String packageRoot = _findPackageRoot();

/// The rule file every test enforces. Tests read the real one on purpose: a
/// rule that only fires against a rule set written for the test is a rule that
/// proves nothing about the workspace.
final String rulesPath = p.join(packageRoot, 'rules.yaml');

/// The directory holding the deliberately broken mini workspaces.
final String fixturesRoot = p.join(packageRoot, 'test', 'fixtures');

/// The path of one fixture workspace.
String fixture(String name) => p.join(fixturesRoot, name);

String _findPackageRoot() {
  var directory = Directory.current.absolute;
  while (true) {
    final candidate = File(p.join(directory.path, 'rules.yaml'));
    if (candidate.existsSync() && p.basename(directory.path) == 'arch_check') {
      return directory.path;
    }
    final nested = File(
      p.join(directory.path, 'tooling', 'arch_check', 'rules.yaml'),
    );
    if (nested.existsSync()) {
      return p.join(directory.path, 'tooling', 'arch_check');
    }
    final parent = directory.parent;
    if (parent.path == directory.path) {
      throw StateError(
        'Could not locate the arch_check package from '
        '${Directory.current.path}.',
      );
    }
    directory = parent;
  }
}
