import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import 'model/test_package.dart';

/// The fingerprint a package's suite passed under.
///
/// It covers the package's own sources **and the sources of everything it
/// depends on inside the workspace**, transitively, plus the resolution. A
/// hash of the package alone would skip `routing_application`'s suite after a
/// change to `core_kernel`, which is the one case the cache exists to get
/// right.
///
/// Generated files are part of it, and that is not an oversight: §4.3 of
/// CLAUDE.md puts them in the repository, so they are part of the package's
/// source. A `.freezed.dart` that changed without its source changing is
/// exactly the staleness a re-run should catch.
final class PackageHasher {
  /// Creates a hasher over the workspace at [rootPath].
  PackageHasher({
    required this.rootPath,
    required List<TestPackage> packages,
  }) : _byName = {for (final package in packages) package.name: package};

  /// The workspace root, whose `pubspec.lock` is part of every hash.
  final String rootPath;

  final Map<String, TestPackage> _byName;
  final Map<String, String> _ownDigests = {};

  /// The files inside a package that count.
  ///
  /// `lib`, `bin` and `test` are the sources; the four configuration files are
  /// what decides how they compile and how they run. `.dart_tool` and `build`
  /// are outputs and would make the hash change on every run.
  static const List<String> countedDirectories = ['lib', 'bin', 'test'];

  /// Configuration files whose contents change what a run means.
  static const List<String> countedFiles = [
    'pubspec.yaml',
    'build.yaml',
    'dart_test.yaml',
    'analysis_options.yaml',
  ];

  /// The fingerprint for [package].
  String hash(TestPackage package) {
    final parts = <String>[
      _lockDigest(),
      for (final name in _closure(package)) '$name:${_ownDigest(name)}',
    ];
    return sha256.convert(utf8.encode(parts.join('\n'))).toString();
  }

  /// [package] and everything it depends on, transitively, by name and sorted.
  List<String> _closure(TestPackage package) {
    final reached = <String>{package.name};
    final queue = [package.name];
    while (queue.isNotEmpty) {
      final current = _byName[queue.removeLast()];
      if (current == null) continue;
      for (final name in current.allDependencies) {
        if (reached.add(name)) queue.add(name);
      }
    }
    return reached.toList()..sort();
  }

  String _ownDigest(String name) {
    final cached = _ownDigests[name];
    if (cached != null) return cached;

    final package = _byName[name];
    if (package == null) return _ownDigests[name] = 'missing';

    final entries = <String>[];
    for (final directory in countedDirectories) {
      final start = Directory(p.join(package.absolutePath, directory));
      if (!start.existsSync()) continue;
      for (final entity in start.listSync(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is! File) continue;
        entries.add(_fileEntry(package.absolutePath, entity));
      }
    }
    for (final fileName in countedFiles) {
      final file = File(p.join(package.absolutePath, fileName));
      if (file.existsSync()) {
        entries.add(_fileEntry(package.absolutePath, file));
      }
    }
    entries.sort();
    return _ownDigests[name] = sha256
        .convert(utf8.encode(entries.join('\n')))
        .toString();
  }

  String _fileEntry(String packagePath, File file) {
    final relative = p.posix.joinAll(
      p.split(p.relative(file.path, from: packagePath)),
    );
    final digest = sha256.convert(file.readAsBytesSync()).toString();
    return '$relative:$digest';
  }

  String _lockDigest() {
    final lock = File(p.join(rootPath, 'pubspec.lock'));
    if (!lock.existsSync()) return 'no-lock';
    return sha256.convert(lock.readAsBytesSync()).toString();
  }
}
