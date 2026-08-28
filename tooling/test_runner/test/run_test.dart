@Tags(['unit'])
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_runner/test_runner.dart';

import 'support/harness.dart';

void main() {
  late Directory workspace;
  late FakeCommands commands;

  setUp(() {
    workspace = copyFixture('mini');
    commands = FakeCommands();
  });

  tearDown(() => workspace.deleteSync(recursive: true));

  var result = (code: 0, out: '', err: '');

  Future<void> run(List<String> arguments) async {
    final out = StringBuffer();
    final err = StringBuffer();
    final code = await runCli(
      ['--root=${workspace.path}', ...arguments],
      out: out,
      err: err,
      commands: commands,
    );
    result = (code: code, out: out.toString(), err: err.toString());
  }

  TestPackage named(String name) => const WorkspaceReader()
      .read(workspace.path)
      .firstWhere((package) => package.name == name);

  group('runner selection', () {
    test('a pure Dart package is run by dart test, with -j', () async {
      await run(['--no-cache', '--package=alpha_api', '--concurrency=4']);

      expect(commands.calls, ['dart test --preset pr -j 4']);
      expect(commands.directories.single, named('alpha_api').absolutePath);
    });

    test('a Flutter package is run by flutter test, without -j', () async {
      // flutter test schedules its own concurrency against a headless engine;
      // overriding it makes a widget suite slower rather than faster.
      await run(['--no-cache', '--package=widget_kit', '--concurrency=4']);

      expect(commands.calls.single, startsWith('flutter test --exclude-tags'));
      expect(commands.calls.single, isNot(contains('-j')));
    });

    test('a failing suite is exit 1 and names the command', () async {
      commands.answer('dart test --preset pr -j 4', failed);

      await run(['--no-cache', '--package=alpha_api', '--concurrency=4']);

      expect(result.code, ExitCodes.failures);
      expect(result.out, contains('Failed:'));
      expect(result.out, contains('alpha_api'));
    });

    test('a suite that selected no test is a pass, not a failure', () async {
      // Exit 79 is `package:test`'s "No tests ran". A tag selection that
      // matches nothing in a package is an answer, not a break — and the
      // `pr` workflow learned that the expensive way.
      commands.answer(
        'dart test --preset pr -j 4',
        const CommandResult(exitCode: 79, stdout: 'No tests ran.', stderr: ''),
      );

      await run(['--no-cache', '--package=alpha_api', '--concurrency=4']);

      expect(result.code, ExitCodes.clean);
      expect(result.out, isNot(contains('Failed:')));
    });

    test('an unknown package name is 64, not a silent empty run', () async {
      await run(['--package=nope']);

      expect(result.code, ExitCodes.misconfigured);
      expect(result.err, contains('no such package'));
    });
  });

  group('the cache', () {
    test('a second run of an unchanged package is skipped', () async {
      await run(['--package=alpha_api']);
      expect(commands.calls, hasLength(1));

      commands.calls.clear();
      await run(['--package=alpha_api']);

      expect(commands.calls, isEmpty);
      expect(result.out, contains('1 skipped'));
    });

    test('a change to a dependency un-skips it', () async {
      await run(['--package=alpha_application']);
      commands.calls.clear();

      File(
        p.join(named('alpha_api').absolutePath, 'lib', 'api.dart'),
      ).writeAsStringSync('const api = 99;');
      await run(['--package=alpha_application']);

      expect(commands.calls, hasLength(1));
    });

    test('a failure is not remembered as a pass', () async {
      commands
        ..answer('dart test --preset pr -j 1', failed)
        ..calls.clear();

      await run(['--package=alpha_api', '--concurrency=1']);
      commands
        ..answer(
          'dart test --preset pr -j 1',
          const CommandResult(exitCode: 0, stdout: '', stderr: ''),
        )
        ..calls.clear();
      await run(['--package=alpha_api', '--concurrency=1']);

      expect(commands.calls, hasLength(1));
    });
  });

  group('selection', () {
    test('--affected reads git and walks the dependents', () async {
      commands.answer(
        'git diff --name-only origin/main...HEAD',
        said('packages/features/alpha/alpha_api/lib/api.dart\n'),
      );

      await run(['--affected', '--list']);

      expect(result.out, contains('alpha_api'));
      expect(result.out, contains('alpha_application'));
      expect(result.out, contains('widget_kit'));
      expect(result.out, isNot(contains('core_kernel')));
    });

    test('a diff git could not answer runs everything, and says so', () async {
      commands.answer('git diff --name-only origin/main...HEAD', failed);

      await run(['--affected', '--list']);

      expect(result.out, contains('running everything'));
      expect(result.out, contains('4 package(s) selected'));
    });

    test('--list runs nothing', () async {
      await run(['--list']);

      expect(commands.calls, isEmpty);
      expect(result.code, ExitCodes.clean);
    });

    test('--bucket outside --total is 64', () async {
      await run(['--bucket=2', '--total=2', '--list']);

      expect(result.code, ExitCodes.misconfigured);
    });
  });

  group('reporting', () {
    test('JUnit records a pass, a failure and a skip', () async {
      await run(['--package=alpha_api', '--concurrency=1']);
      commands.answer('dart test --preset pr -j 1', failed);

      await run([
        '--package=alpha_api',
        '--package=core_kernel',
        '--package=widget_kit',
        '--concurrency=1',
        '--junit=build/junit.xml',
      ]);

      final xml = File(
        p.join(workspace.path, 'build', 'junit.xml'),
      ).readAsStringSync();
      expect(xml, contains('<testsuites name="peyk" tests="3"'));
      expect(xml, contains('skipped="1"'));
      expect(
        xml,
        contains('<skipped message="unchanged since it last passed"'),
      );
      expect(xml, contains('<failure message="suite failed">'));
    });

    test('timings are written so the next run can balance buckets', () async {
      await run(['--no-cache', '--package=alpha_api']);

      final timings = File(
        p.join(workspace.path, '.cache', 'timings.json'),
      ).readAsStringSync();
      expect(timings, contains('alpha_api'));
    });
  });

  group('bundling', () {
    test('writes one entrypoint, runs it, and removes it', () async {
      await run([
        '--no-cache',
        '--bundle',
        '--package=alpha_api',
        '--concurrency=1',
      ]);

      expect(
        commands.calls.single,
        'dart test --preset pr -j 1 test/${TestBundle.fileName}',
      );
      expect(
        File(
          p.join(named('alpha_api').absolutePath, 'test', TestBundle.fileName),
        ).existsSync(),
        isFalse,
        reason: 'a bundle left behind would be committed by the next git add',
      );
    });

    test('a package with one test file is not bundled', () async {
      // Bundling one file saves nothing and adds a file to explain.
      await run([
        '--no-cache',
        '--bundle',
        '--package=core_kernel',
        '--concurrency=1',
      ]);

      expect(commands.calls.single, 'dart test --preset pr -j 1');
    });

    test('the entrypoint groups by file so a failure names one', () {
      final bundle = TestBundle.write(named('alpha_api'))!;
      final source = bundle.file.readAsStringSync();
      addTearDown(bundle.delete);

      expect(bundle.fileCount, 2);
      expect(source, contains("import 'one_test.dart' as suite0;"));
      expect(source, contains("group('one_test.dart', suite0.main);"));
      expect(source, contains("group('two_test.dart', suite1.main);"));
    });
  });
}
