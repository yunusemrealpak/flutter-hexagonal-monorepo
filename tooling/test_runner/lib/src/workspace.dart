import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'model/test_package.dart';

/// Reads the workspace the way pub does: from the root pubspec's `workspace:`
/// list.
///
/// Not a directory walk. That list is what pub resolves against, so a package
/// missing from it is a package no test run should pretend to cover — and a
/// directory holding a pubspec that nobody registered is exactly the mistake
/// `arch_check` reports as `unregistered_package`.
final class WorkspaceReader {
  /// Creates a reader.
  const WorkspaceReader();

  /// Every registered package under [rootPath], ordered by path.
  ///
  /// Throws [FormatException] when the root pubspec has no `workspace:` list,
  /// because a runner that silently found nothing to run reports success.
  List<TestPackage> read(String rootPath) {
    final root = p.normalize(p.absolute(rootPath));
    final rootPubspec = File(p.join(root, 'pubspec.yaml'));
    if (!rootPubspec.existsSync()) {
      throw FormatException('no pubspec.yaml at $root');
    }
    final document = _parse(rootPubspec.readAsStringSync());
    final entries = document?['workspace'];
    if (entries is! YamlList || entries.isEmpty) {
      throw const FormatException('the root pubspec has no workspace: list');
    }

    final raw = <String, YamlMap>{};
    final paths = <String, String>{};
    for (final entry in entries) {
      final relativePath = p.posix.normalize(entry.toString());
      final directory = p.join(root, relativePath);
      final pubspec = File(p.join(directory, 'pubspec.yaml'));
      if (!pubspec.existsSync()) continue;
      final parsed = _parse(pubspec.readAsStringSync());
      if (parsed == null) continue;
      final name = parsed['name']?.toString() ?? p.basename(directory);
      raw[name] = parsed;
      paths[name] = relativePath;
    }

    final known = raw.keys.toSet();
    final packages = <TestPackage>[];
    for (final entry in raw.entries) {
      final name = entry.key;
      final pubspec = entry.value;
      final relativePath = paths[name]!;
      final absolutePath = p.join(root, relativePath);
      packages.add(
        TestPackage(
          name: name,
          relativePath: relativePath,
          absolutePath: absolutePath,
          dependencies: _internal(pubspec['dependencies'], known),
          devDependencies: _internal(pubspec['dev_dependencies'], known),
          usesFlutter: _usesFlutter(pubspec),
          hasTests: _hasTests(absolutePath),
        ),
      );
    }

    packages.sort((a, b) => a.relativePath.compareTo(b.relativePath));
    return packages;
  }

  List<String> _internal(Object? block, Set<String> known) {
    if (block is! YamlMap) return const [];
    return [
      for (final key in block.keys)
        if (known.contains(key.toString())) key.toString(),
    ]..sort();
  }

  /// Whether a package binds to Flutter.
  ///
  /// Read from the pubspec rather than guessed from the path: a `platform/*`
  /// package is Flutter and a `_api` package is not, and both live two levels
  /// under `packages/`. A `sdk: flutter` entry in either dependency block is
  /// the fact, because a package with `flutter_test` in `dev_dependencies:`
  /// still cannot be started by `dart test`.
  bool _usesFlutter(YamlMap pubspec) {
    for (final block in ['dependencies', 'dev_dependencies']) {
      final entries = pubspec[block];
      if (entries is! YamlMap) continue;
      for (final entry in entries.entries) {
        final value = entry.value;
        if (value is YamlMap && value['sdk']?.toString() == 'flutter') {
          return true;
        }
      }
    }
    return false;
  }

  bool _hasTests(String packagePath) {
    final directory = Directory(p.join(packagePath, 'test'));
    if (!directory.existsSync()) return false;
    return directory
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .any((file) => file.path.endsWith('_test.dart'));
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
