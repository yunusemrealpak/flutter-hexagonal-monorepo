import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'model/dependency.dart';
import 'model/package_type.dart';
import 'model/violation.dart';
import 'model/workspace.dart';
import 'model/workspace_package.dart';
import 'rules/rule_set.dart';

/// The outcome of reading a workspace off disk.
///
/// A package whose path and name resolve to no type — or to more than one —
/// cannot be checked against any rule, so it is reported here and left out of
/// [workspace]. Every other check then works with a total function from
/// package to type instead of a nullable one.
final class LoadResult {
  /// Creates the result of a load.
  const LoadResult({required this.workspace, required this.violations});

  /// Every package whose type could be determined.
  final Workspace workspace;

  /// The packages whose type could not be, one violation each.
  final List<Violation> violations;
}

/// Reads every package under the discovery roots, once.
final class WorkspaceLoader {
  /// Creates a loader that reads a workspace the way [rules] describes.
  const WorkspaceLoader(this.rules);

  /// The rules that say where packages live and what type each one is.
  final RuleSet rules;

  /// Reads every package under [rootPath].
  LoadResult load(String rootPath) {
    final root = p.normalize(p.absolute(rootPath));
    final registered = _registeredPaths(root);
    final violations = <Violation>[];
    final packages = <WorkspacePackage>[];

    for (final directory in _discover(root)) {
      final relativePath = relativePosix(directory.path, root);
      final pubspecFile = File(p.join(directory.path, 'pubspec.yaml'));
      final pubspec = _parseYamlMap(pubspecFile.readAsStringSync());
      if (pubspec == null) continue;

      final directoryName = p.basename(directory.path);
      final name = pubspec['name']?.toString() ?? directoryName;

      // Inference reads the directory name, not the pubspec's `name:`.
      //
      // Both are "the name" as far as section 1 is concerned, and rule S5
      // requires them to be equal — but only one of them is a fact about the
      // filesystem. When they disagree, taking the pubspec's word for it makes
      // the package fall out of every type and turns one obvious violation
      // (name_mismatch) into a silence about the other twenty rules. Taking
      // the directory's word keeps the package in the graph and reports the
      // mismatch on its own.
      final matched = rules.typeMatchers
          .where(
            (matcher) => matcher.matches(
              relativePath: relativePath,
              name: directoryName,
            ),
          )
          .map((matcher) => matcher.type)
          .toSet();

      if (matched.length != 1) {
        violations.add(
          Violation(
            code: 'unknown_package_type',
            location: ViolationLocation(package: relativePath),
            what: matched.isEmpty
                ? '$relativePath matches no package type'
                : '$relativePath matches ${matched.length} package types: '
                      '${_sortedIds(matched)}',
            remedy: rules.remedyFor('unknown_package_type'),
          ),
        );
        continue;
      }

      final type = matched.single;
      packages.add(
        WorkspacePackage(
          name: name,
          directoryName: directoryName,
          relativePath: relativePath,
          absolutePath: directory.path,
          type: type,
          owningFeature: _owningFeature(type, relativePath),
          dependencies: _dependencies(pubspec['dependencies']),
          devDependencies: _dependencies(pubspec['dev_dependencies']),
          declaresWorkspaceResolution: pubspec['resolution'] == 'workspace',
          isRegisteredInWorkspace: registered.contains(relativePath),
          buildConfig: _buildConfig(directory.path),
        ),
      );
    }

    packages.sort((a, b) => a.relativePath.compareTo(b.relativePath));
    return LoadResult(
      workspace: Workspace(rootPath: root, packages: packages),
      violations: violations,
    );
  }

  /// Directories that hold a pubspec, under the discovery roots.
  ///
  /// Packages do not nest, so a directory with a pubspec is not descended
  /// into. That is also what keeps this checker's own fixtures — deliberately
  /// broken mini workspaces under `test/fixtures/` — out of a run against the
  /// real workspace, together with `test` on the skip list.
  List<Directory> _discover(String root) {
    final found = <Directory>[];
    for (final rootName in rules.discovery.roots) {
      final start = Directory(p.join(root, rootName));
      if (!start.existsSync()) continue;
      _walk(start, found);
    }
    found.sort((a, b) => a.path.compareTo(b.path));
    return found;
  }

  void _walk(Directory directory, List<Directory> found) {
    if (rules.discovery.skipDirectories.contains(p.basename(directory.path))) {
      return;
    }
    if (File(p.join(directory.path, 'pubspec.yaml')).existsSync()) {
      found.add(directory);
      return;
    }
    for (final entity in directory.listSync(followLinks: false)) {
      if (entity is Directory) _walk(entity, found);
    }
  }

  Set<String> _registeredPaths(String root) {
    final pubspec = File(p.join(root, 'pubspec.yaml'));
    if (!pubspec.existsSync()) return const {};
    final document = _parseYamlMap(pubspec.readAsStringSync());
    final workspace = document?['workspace'];
    if (workspace is! YamlList) return const {};
    return workspace
        .map((entry) => p.posix.normalize(entry.toString()))
        .toSet();
  }

  String _sortedIds(Set<PackageType> types) =>
      (types.map((type) => type.id).toList()..sort()).join(', ');

  String? _owningFeature(PackageType type, String relativePath) {
    if (!type.isFeature) return null;
    final prefix = '${rules.featureRoot}/';
    if (!relativePath.startsWith(prefix)) return null;
    final rest = relativePath.substring(prefix.length).split('/');
    return rest.isEmpty ? null : rest.first;
  }

  List<Dependency> _dependencies(Object? block) {
    if (block is! YamlMap) return const [];
    return [
      for (final entry in block.entries)
        Dependency(
          name: entry.key.toString(),
          sdk: entry.value is YamlMap
              ? (entry.value as YamlMap)['sdk']?.toString()
              : null,
        ),
    ];
  }

  YamlMap? _buildConfig(String packagePath) {
    final file = File(p.join(packagePath, 'build.yaml'));
    if (!file.existsSync()) return null;
    return _parseYamlMap(file.readAsStringSync());
  }

  /// A pubspec or build file that does not parse is left out rather than
  /// crashing the run. The analyzer and pub both report a malformed YAML file
  /// far better than an architecture checker can, and a run that dies on one
  /// bad file reports nothing about the other seventy-four packages.
  YamlMap? _parseYamlMap(String source) {
    try {
      final document = loadYaml(source);
      return document is YamlMap ? document : null;
    } on YamlException {
      return null;
    }
  }
}
