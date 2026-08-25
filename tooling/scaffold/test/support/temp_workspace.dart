import 'dart:io';

import 'package:path/path.dart' as p;

/// A throwaway workspace on disk, with just enough in it for the scaffolder
/// to have something to register against and for arch_check to type the edges
/// a generated feature declares.
///
/// Generating into a temporary directory rather than into the repository is
/// what lets these tests assert on a whole tree — files written, files
/// skipped, the root pubspec after the edit — without leaving anything behind
/// or depending on what phase the real workspace happens to be in.
final class TempWorkspace {
  TempWorkspace._(this.root);

  /// Creates the directory and writes the root pubspec and the core stubs.
  factory TempWorkspace.create({
    Iterable<String> corePackages = const [
      'core_kernel',
      'core_navigation',
      'core_ports',
      'core_testing',
    ],
  }) {
    final directory = Directory.systemTemp.createTempSync('scaffold_test_');
    final workspace = TempWorkspace._(directory.path);
    corePackages.forEach(workspace._writeStub);
    workspace._writeRootPubspec(corePackages);
    return workspace;
  }

  /// The workspace root.
  final String root;

  /// Reads a file by its workspace-relative posix path.
  String read(String relative) =>
      File(p.join(root, p.joinAll(p.posix.split(relative)))).readAsStringSync();

  /// Overwrites a file by its workspace-relative posix path.
  void write(String relative, String content) => _write(
    p.join(root, p.joinAll(p.posix.split(relative))),
    content,
  );

  /// Whether a workspace-relative path exists.
  bool exists(String relative) =>
      File(p.join(root, p.joinAll(p.posix.split(relative)))).existsSync();

  /// Every file under the workspace, as workspace-relative posix paths.
  List<String> files() =>
      Directory(root)
          .listSync(recursive: true)
          .whereType<File>()
          .map(
            (file) =>
                p.posix.joinAll(p.split(p.relative(file.path, from: root))),
          )
          .toList()
        ..sort();

  /// Deletes the directory.
  void dispose() {
    final directory = Directory(root);
    if (directory.existsSync()) directory.deleteSync(recursive: true);
  }

  void _writeStub(String name) {
    final directory = p.join(root, 'packages', 'core', name);
    final dependencies = name == 'core_kernel'
        ? ''
        : '\ndependencies:\n  core_kernel: ^0.1.0\n';
    _write(p.join(directory, 'pubspec.yaml'), '''
name: $name
publish_to: none
version: 0.1.0
resolution: workspace

environment:
  sdk: ^3.12.0
$dependencies''');
    _write(p.join(directory, 'lib', '$name.dart'), '''
/// A stub of $name, present so that a generated feature has something real to
/// depend on.
library;

export 'src/stub.dart';
''');
    _write(p.join(directory, 'lib', 'src', 'stub.dart'), '''
/// Nothing here is used; the package exists so the edge can be typed.
const String stub = '$name';
''');
  }

  void _writeRootPubspec(Iterable<String> corePackages) {
    final members = corePackages
        .map((name) => '  - packages/core/$name')
        .join('\n');
    _write(p.join(root, 'pubspec.yaml'), '''
name: fixture_workspace
publish_to: none
version: 0.0.0

# A comment inside the root pubspec, present so that a test can prove the
# scaffolder's edit does not eat it.
workspace:
$members

environment:
  sdk: ^3.12.0
''');
  }

  void _write(String path, String content) => File(path)
    ..createSync(recursive: true)
    ..writeAsStringSync(content);
}
