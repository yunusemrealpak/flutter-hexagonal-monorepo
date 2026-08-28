import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test_runner/test_runner.dart';

/// Locates this package and its fixtures from wherever the tests were started.
final String packageRoot = _findPackageRoot();

/// The directory holding the mini workspaces the tests read.
final String fixturesRoot = p.join(packageRoot, 'test', 'fixtures');

/// The path of one fixture workspace.
String fixture(String name) => p.join(fixturesRoot, name);

/// Copies a fixture into a temporary directory the test may write to.
Directory copyFixture(String name) {
  final target = Directory.systemTemp.createTempSync('test_runner_$name');
  final source = Directory(fixture(name));
  for (final entity in source.listSync(recursive: true, followLinks: false)) {
    final relative = p.relative(entity.path, from: source.path);
    final destination = p.join(target.path, relative);
    if (entity is Directory) {
      Directory(destination).createSync(recursive: true);
    } else if (entity is File) {
      Directory(p.dirname(destination)).createSync(recursive: true);
      entity.copySync(destination);
    }
  }
  return target;
}

/// A [CommandRunner] that answers from a script and records what it was asked.
///
/// Every decision this tool makes is decided by what a subprocess said, so a
/// test that had to launch `git` and `flutter` to check the decision would not
/// be a test of the decision.
final class FakeCommands implements CommandRunner {
  /// Creates a runner that answers [answers], keyed by the joined command.
  FakeCommands({
    Map<String, CommandResult> answers = const {},
    this.fallback = const CommandResult(exitCode: 0, stdout: '', stderr: ''),
  }) : _answers = {...answers};

  final Map<String, CommandResult> _answers;

  /// What an unscripted command answers.
  final CommandResult fallback;

  /// Every command run, joined, in order.
  final List<String> calls = [];

  /// The working directory each call was made in.
  final List<String?> directories = [];

  /// Scripts [key] — the joined command line — to answer [result].
  void answer(String key, CommandResult result) => _answers[key] = result;

  @override
  Future<CommandResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    bool inheritStdio = false,
  }) async {
    final key = [executable, ...arguments].join(' ');
    calls.add(key);
    directories.add(workingDirectory);
    return _answers[key] ?? fallback;
  }
}

/// A successful command with [stdout] on its output.
CommandResult said(String stdout) =>
    CommandResult(exitCode: 0, stdout: stdout, stderr: '');

/// A failed command.
const CommandResult failed = CommandResult(
  exitCode: 1,
  stdout: '',
  stderr: 'no',
);

String _findPackageRoot() {
  var directory = Directory.current.absolute;
  while (true) {
    if (p.basename(directory.path) == 'test_runner' &&
        File(p.join(directory.path, 'pubspec.yaml')).existsSync()) {
      return directory.path;
    }
    final nested = p.join(directory.path, 'tooling', 'test_runner');
    if (File(p.join(nested, 'pubspec.yaml')).existsSync()) return nested;
    final parent = directory.parent;
    if (parent.path == directory.path) {
      throw StateError(
        'Could not locate the test_runner package from '
        '${Directory.current.path}.',
      );
    }
    directory = parent;
  }
}
