import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart' as p;

import 'model/violation.dart';
import 'model/workspace.dart';
import 'model/workspace_package.dart';

/// One parsed Dart file.
///
/// Parsed, not resolved. Resolution would need a working pub solution for
/// every package, which is exactly what a workspace in trouble does not have —
/// and it is the difference between a run measured in hundreds of milliseconds
/// and one measured in minutes. Every rule this checker enforces is decidable
/// from syntax: an import URI is a string, and rules A1 to A5 are about the
/// shape of a call rather than about which declaration it binds to.
final class SourceFile {
  /// Creates a parsed file record.
  const SourceFile({
    required this.absolutePath,
    required this.relativePath,
    required this.directory,
    required this.unit,
    required this.lineInfo,
  });

  /// The file's absolute path.
  final String absolutePath;

  /// Path relative to the workspace root, posix form.
  final String relativePath;

  /// The top-level package directory this file was found under: `lib`, `test`
  /// or `bin`.
  final String directory;

  /// The unresolved compilation unit.
  final CompilationUnit unit;

  /// Line starts, used to turn an offset into a line number.
  final LineInfo lineInfo;

  /// The file's base name, such as `shipment_dto.g.dart`.
  String get fileName => p.posix.basename(relativePath);

  /// The 1-based line an offset falls on.
  int lineOf(int offset) => lineInfo.getLocation(offset).lineNumber;

  /// Every `import`, `export` and `part` URI in the file, with its line.
  Iterable<({String uri, int line})> get uriDirectives sync* {
    for (final directive in unit.directives) {
      final String? uri;
      if (directive is ImportDirective) {
        uri = directive.uri.stringValue;
      } else if (directive is ExportDirective) {
        uri = directive.uri.stringValue;
      } else if (directive is PartDirective) {
        uri = directive.uri.stringValue;
      } else {
        uri = null;
      }
      if (uri != null) {
        yield (uri: uri, line: lineOf(directive.offset));
      }
    }
  }
}

/// The Dart sources of one package, grouped by the directory they live in.
final class PackageSources {
  /// Creates a package's sources, grouped by top-level directory.
  const PackageSources(this._byDirectory);

  final Map<String, List<SourceFile>> _byDirectory;

  /// The files under one of the package's top-level directories.
  List<SourceFile> inDirectory(String directory) =>
      _byDirectory[directory] ?? const [];

  /// The files under any of [directories], in the order given.
  Iterable<SourceFile> inDirectories(Iterable<String> directories) sync* {
    for (final directory in directories) {
      yield* inDirectory(directory);
    }
  }

  /// Every parsed file of the package.
  Iterable<SourceFile> get all => _byDirectory.values.expand((files) => files);
}

/// Parses each package's sources once and hands the same trees to every rule.
///
/// Rules ask for the directories they care about, so a package's `test/` tree
/// is only parsed if some rule scans it.
final class SourceIndex {
  /// Creates an index over [_workspace], reading [directories] of each
  /// package it is asked about.
  SourceIndex(
    this._workspace, {
    this.directories = const ['lib', 'bin', 'test'],
  });

  final Workspace _workspace;

  /// The top-level package directories this index reads.
  final List<String> directories;

  final Map<String, PackageSources> _cache = {};

  /// The parsed sources of [package], read on first use and kept.
  PackageSources of(WorkspacePackage package) =>
      _cache[package.relativePath] ??= _read(package);

  PackageSources _read(WorkspacePackage package) {
    final byDirectory = <String, List<SourceFile>>{};
    for (final directory in directories) {
      final root = Directory(p.join(package.absolutePath, directory));
      if (!root.existsSync()) continue;
      final files = <SourceFile>[];
      _collect(root, directory, files);
      files.sort((a, b) => a.relativePath.compareTo(b.relativePath));
      byDirectory[directory] = files;
    }
    return PackageSources(byDirectory);
  }

  /// Walks one of a package's directories, stopping at a nested package.
  ///
  /// A subdirectory with a pubspec of its own is somebody else's source, not
  /// this package's. The case that made this explicit is this checker: its
  /// fixtures are real mini workspaces under `test/`, and reading them as
  /// arch_check's own sources reported every deliberate violation in them as
  /// a violation of the workspace being checked.
  void _collect(Directory directory, String topLevel, List<SourceFile> into) {
    // The walk starts at the package's own lib/, bin/ or test/, and a package
    // never keeps its pubspec in one of those. So a pubspec found here always
    // belongs to a package nested inside, and its sources are not ours.
    if (File(p.join(directory.path, 'pubspec.yaml')).existsSync()) return;

    for (final entity in directory.listSync(followLinks: false)) {
      if (entity is Directory) {
        if (_skipped.contains(p.basename(entity.path))) continue;
        _collect(entity, topLevel, into);
        continue;
      }
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final parsed = parseString(
        content: entity.readAsStringSync(),
        path: entity.path,
        throwIfDiagnostics: false,
      );
      into.add(
        SourceFile(
          absolutePath: entity.path,
          relativePath: relativePosix(entity.path, _workspace.rootPath),
          directory: topLevel,
          unit: parsed.unit,
          lineInfo: parsed.lineInfo,
        ),
      );
    }
  }

  /// Build output and tool caches hold no source worth reading.
  static const Set<String> _skipped = {'.dart_tool', 'build'};
}
