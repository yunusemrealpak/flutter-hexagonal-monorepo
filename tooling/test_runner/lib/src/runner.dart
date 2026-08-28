import 'dart:io';

import 'bundle.dart';
import 'model/package_result.dart';
import 'model/test_package.dart';
import 'process.dart';

/// Runs one package's suite with the runner that package needs.
///
/// **Runner selection is read from the pubspec, never guessed from the path.**
/// `dart test` cannot start a package that binds to Flutter, and `flutter
/// test` costs several seconds of start-up for one that does not — across the
/// forty-odd pure Dart packages here that is the larger half of a full run.
final class SuiteRunner {
  /// Creates a runner.
  const SuiteRunner({
    required this._commands,
    required this.rootPath,
    this.preset = 'pr',
    this.excludeTags = 'golden || integration || flaky',
    this.bundle = false,
    this.concurrency,
  });

  final CommandRunner _commands;

  /// The workspace root, which is where the commands are launched from.
  final String rootPath;

  /// The `dart test` preset. `flutter test` has no `--preset`, so the same
  /// selection is spelled out in [excludeTags] for it.
  final String preset;

  /// The tags a Flutter package's run excludes, mirroring the preset.
  final String excludeTags;

  /// Whether to compile each package's test files into one entrypoint.
  final bool bundle;

  /// `-j` for pure Dart packages. Defaults to the machine's core count.
  ///
  /// Not passed to `flutter test`: it schedules its own concurrency against a
  /// device or a headless engine, and overriding it makes a widget suite
  /// slower rather than faster.
  final int? concurrency;

  /// Runs [package] and reports what happened.
  Future<PackageResult> run(TestPackage package) async {
    final stopwatch = Stopwatch()..start();
    TestBundle? bundled;
    try {
      if (bundle) bundled = TestBundle.write(package);
      final command = _commandFor(package, bundled);
      final result = await _commands.run(
        command.first,
        command.skip(1).toList(),
        workingDirectory: package.absolutePath,
        inheritStdio: true,
      );
      stopwatch.stop();
      return PackageResult(
        package: package.name,
        status: result.ok ? RunStatus.passed : RunStatus.failed,
        duration: stopwatch.elapsed,
        command: command,
        fileCount: bundled?.fileCount,
      );
    } finally {
      // In a `finally` because a bundle left behind by a crashed run would be
      // committed by the next person who typed `git add -A`.
      bundled?.delete();
    }
  }

  /// The command [package] is run with.
  List<String> _commandFor(TestPackage package, TestBundle? bundled) {
    final target = bundled == null ? null : 'test/${TestBundle.fileName}';
    if (package.usesFlutter) {
      return [
        'flutter',
        'test',
        '--exclude-tags',
        excludeTags,
        ?target,
      ];
    }
    return [
      'dart',
      'test',
      '--preset',
      preset,
      '-j',
      '${concurrency ?? Platform.numberOfProcessors}',
      ?target,
    ];
  }
}
