import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Thrown when the root pubspec is not something the scaffolder can edit.
final class WorkspaceRegistrationException implements Exception {
  /// Creates the exception with the sentence printed after the tool's name.
  const WorkspaceRegistrationException(this.message);

  /// What is wrong.
  final String message;

  @override
  String toString() => message;
}

/// Reads and edits the `workspace:` list in the root pubspec.
///
/// The edit is done on the file's lines rather than through a YAML writer, and
/// that is deliberate. The root pubspec is mostly comments — the reasoning
/// behind the melos scripts lives there — and a round trip through a YAML
/// document model is a round trip that loses them. Splicing one sorted block
/// of list items touches exactly the lines it means to.
final class WorkspaceRegistration {
  /// Reads the root pubspec at [rootPath].
  WorkspaceRegistration(this.rootPath);

  /// The workspace root directory.
  final String rootPath;

  File get _pubspec => File(p.join(rootPath, 'pubspec.yaml'));

  /// The paths already in the `workspace:` list, in file order.
  List<String> read() {
    final document = _parse();
    final workspace = document['workspace'];
    if (workspace is! YamlList) {
      throw const WorkspaceRegistrationException(
        'the root pubspec.yaml has no workspace: list',
      );
    }
    return workspace.map((entry) => entry.toString()).toList();
  }

  /// The names of the packages already in the workspace.
  ///
  /// A package's directory name is its name — rule S5 — so the basename of a
  /// registered path is enough, and it costs no filesystem access.
  Set<String> registeredPackageNames() => read().map(p.posix.basename).toSet();

  /// Whether the workspace already contains a package at [relativePath].
  bool contains(String relativePath) => read().contains(relativePath);

  /// Adds [paths] to the list, keeping it sorted, and returns the new file
  /// content. Paths already present are left alone.
  ///
  /// Returns `null` when nothing would change, so a caller can tell "already
  /// registered" from "registered just now" without diffing.
  String? withPaths(Iterable<String> paths) {
    final lines = _pubspec.readAsLinesSync();
    final start = lines.indexWhere((line) => line.trimRight() == 'workspace:');
    if (start == -1) {
      throw const WorkspaceRegistrationException(
        'the root pubspec.yaml has no workspace: list',
      );
    }

    var end = start + 1;
    while (end < lines.length && lines[end].startsWith('  - ')) {
      end++;
    }

    final existing = lines
        .sublist(start + 1, end)
        .map((line) => line.substring('  - '.length).trim())
        .toList();
    final merged = {...existing, ...paths}.toList()..sort();
    if (merged.length == existing.length &&
        List.generate(
          merged.length,
          (i) => merged[i] == existing[i],
        ).every((same) => same)) {
      return null;
    }

    final rebuilt = [
      ...lines.sublist(0, start + 1),
      ...merged.map((path) => '  - $path'),
      ...lines.sublist(end),
    ];
    return '${rebuilt.join('\n')}\n';
  }

  /// Writes [content] back to the root pubspec.
  void write(String content) => _pubspec.writeAsStringSync(content);

  YamlMap _parse() {
    if (!_pubspec.existsSync()) {
      throw WorkspaceRegistrationException(
        'no pubspec.yaml at $rootPath — is this a workspace root?',
      );
    }
    final document = loadYaml(_pubspec.readAsStringSync());
    if (document is! YamlMap) {
      throw const WorkspaceRegistrationException(
        'the root pubspec.yaml is not a YAML map',
      );
    }
    return document;
  }
}
