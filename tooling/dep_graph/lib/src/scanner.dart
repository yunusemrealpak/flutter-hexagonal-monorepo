import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'model/package_node.dart';
import 'type_matchers.dart';

/// Reads every package under the discovery roots into a list of nodes.
///
/// The same walk `arch_check` does, and deliberately a second copy of it: §2
/// gives a tooling package an empty allow-list, so this tool may not import
/// that one. What is *not* duplicated is the decision about a package's type —
/// that comes from the same `rules.yaml`, read as data.
final class WorkspaceScanner {
  /// Creates a scanner over [rules].
  const WorkspaceScanner(this.rules);

  /// Where packages live and what type each one is.
  final TypeRules rules;

  /// Every package found under [rootPath], ordered by path.
  List<PackageNode> scan(String rootPath) {
    final root = p.normalize(p.absolute(rootPath));
    final nodes = <PackageNode>[];

    for (final directory in _discover(root)) {
      final pubspec = _parse(
        File(p.join(directory.path, 'pubspec.yaml')).readAsStringSync(),
      );
      if (pubspec == null) continue;

      final relativePath = p.posix.joinAll(
        p.split(p.relative(directory.path, from: root)),
      );
      final directoryName = p.basename(directory.path);
      final typeId = rules.typeOf(
        relativePath: relativePath,
        name: directoryName,
      );

      nodes.add(
        PackageNode(
          name: pubspec['name']?.toString() ?? directoryName,
          relativePath: relativePath,
          typeId: typeId,
          owningFeature: _owningFeature(relativePath),
          dependencies: _names(pubspec['dependencies']),
          devDependencies: _names(pubspec['dev_dependencies']),
        ),
      );
    }

    nodes.sort((a, b) => a.relativePath.compareTo(b.relativePath));
    return nodes;
  }

  List<Directory> _discover(String root) {
    final found = <Directory>[];
    for (final rootName in rules.roots) {
      final start = Directory(p.join(root, rootName));
      if (start.existsSync()) _walk(start, found);
    }
    found.sort((a, b) => a.path.compareTo(b.path));
    return found;
  }

  void _walk(Directory directory, List<Directory> found) {
    if (rules.skipDirectories.contains(p.basename(directory.path))) return;
    if (File(p.join(directory.path, 'pubspec.yaml')).existsSync()) {
      found.add(directory);
      return;
    }
    for (final entity in directory.listSync(followLinks: false)) {
      if (entity is Directory) _walk(entity, found);
    }
  }

  String? _owningFeature(String relativePath) {
    final prefix = '${rules.featureRoot}/';
    if (!relativePath.startsWith(prefix)) return null;
    final rest = relativePath.substring(prefix.length).split('/');
    return rest.isEmpty ? null : rest.first;
  }

  List<String> _names(Object? block) {
    if (block is! YamlMap) return const [];
    return [for (final key in block.keys) key.toString()]..sort();
  }

  YamlMap? _parse(String source) {
    try {
      final document = loadYaml(source);
      return document is YamlMap ? document : null;
    } on YamlException {
      return null;
    }
  }
}
