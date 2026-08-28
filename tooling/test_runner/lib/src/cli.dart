import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import 'affected.dart';
import 'bucketing.dart';
import 'cache.dart';
import 'git.dart';
import 'hashing.dart';
import 'model/package_result.dart';
import 'model/test_package.dart';
import 'process.dart';
import 'report/junit.dart';
import 'report/summary.dart';
import 'runner.dart';
import 'timings.dart';
import 'workspace.dart';

/// Exit codes, kept distinct on purpose.
abstract final class ExitCodes {
  /// Everything selected passed, or nothing was selected.
  static const int clean = 0;

  /// At least one package's suite failed.
  static const int failures = 1;

  /// The runner could not run: bad arguments, no workspace list.
  static const int misconfigured = 64;
}

/// Parses arguments, selects packages, runs them, returns an exit code.
///
/// Nothing here calls `exit()`. The entrypoint does that, so a test can drive
/// the whole command with a fake [CommandRunner] and read what it decided.
Future<int> runCli(
  List<String> arguments, {
  required StringSink out,
  StringSink? err,
  CommandRunner commands = const SystemCommandRunner(),
}) async {
  final errors = err ?? out;
  final parser = _parser();

  final ArgResults options;
  try {
    options = parser.parse(arguments);
  } on FormatException catch (error) {
    errors
      ..writeln(error.message)
      ..writeln(_usage(parser));
    return ExitCodes.misconfigured;
  }

  if (options.flag('help')) {
    out.writeln(_usage(parser));
    return ExitCodes.clean;
  }

  final root = p.normalize(p.absolute(options.option('root')!));
  final List<TestPackage> workspace;
  try {
    workspace = const WorkspaceReader().read(root);
  } on FormatException catch (error) {
    errors.writeln('test_runner: ${error.message}');
    return ExitCodes.misconfigured;
  }

  final selection = await _select(
    options,
    workspace: workspace,
    root: root,
    commands: commands,
    out: out,
    errors: errors,
  );
  if (selection == null) return ExitCodes.misconfigured;

  final total = int.tryParse(options.option('total') ?? '1') ?? 1;
  final index = int.tryParse(options.option('bucket') ?? '0') ?? 0;
  if (total < 1 || index < 0 || index >= total) {
    errors.writeln('test_runner: --bucket must be in [0, --total).');
    return ExitCodes.misconfigured;
  }

  final timings = Timings.load(Timings.pathFor(root));
  final selected = bucketOf(
    selection,
    timings,
    index: index,
    total: total,
  );

  if (options.flag('list')) {
    out.writeln(Summary.listing(selected.map((package) => package.name)));
    return ExitCodes.clean;
  }

  final useCache = options.flag('cache');
  final cache = TestHashCache.load(TestHashCache.pathFor(root));
  final hasher = PackageHasher(rootPath: root, packages: workspace);
  final runner = SuiteRunner(
    commands: commands,
    rootPath: root,
    preset: options.option('preset')!,
    bundle: options.flag('bundle'),
    concurrency: int.tryParse(options.option('concurrency') ?? ''),
  );

  final results = <PackageResult>[];
  for (final package in selected) {
    final hash = hasher.hash(package);
    if (useCache && cache.isFresh(package.name, hash)) {
      results.add(
        PackageResult(
          package: package.name,
          status: RunStatus.skipped,
          duration: Duration.zero,
        ),
      );
      continue;
    }

    out.writeln('▶ ${package.name}');
    final result = await runner.run(package);
    results.add(result);

    if (result.failed) {
      // Forgotten rather than left alone: a package that passed, then broke,
      // must not be skipped on the next run because of the older entry.
      cache.forget(package.name);
    } else {
      cache.record(package.name, hash);
      timings.record(package.name, result.duration.inMilliseconds / 1000);
    }
  }

  if (useCache) cache.save();
  timings.save();

  final junitPath = options.option('junit');
  if (junitPath != null) {
    final file = File(p.normalize(p.join(root, junitPath)))
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(JUnitReport.render(results));
    out.writeln('test_runner: wrote ${p.relative(file.path, from: root)}');
  }

  out.writeln(Summary.render(results));
  return results.any((result) => result.failed)
      ? ExitCodes.failures
      : ExitCodes.clean;
}

/// Which packages this invocation is about, before bucketing.
Future<List<TestPackage>?> _select(
  ArgResults options, {
  required List<TestPackage> workspace,
  required String root,
  required CommandRunner commands,
  required StringSink out,
  required StringSink errors,
}) async {
  final named = options.multiOption('package');
  if (named.isNotEmpty) {
    final byName = {for (final package in workspace) package.name: package};
    final unknown = named.where((name) => !byName.containsKey(name)).toList();
    if (unknown.isNotEmpty) {
      errors.writeln('test_runner: no such package: ${unknown.join(', ')}');
      return null;
    }
    return [
      for (final package in workspace)
        if (named.contains(package.name) && package.hasTests) package,
    ];
  }

  final withTests = [
    for (final package in workspace)
      if (package.hasTests) package,
  ];
  if (!options.flag('affected')) return withTests;

  final base = options.option('base')!;
  final changed = await GitChanges(commands).since(base, root: root);
  if (changed == null) {
    // The only safe fallback. A selective run built on a failed diff is a run
    // that silently covers nothing, and the shape of that failure — a green
    // CI on an unfetched base — is exactly the one nobody notices.
    out.writeln(
      'test_runner: could not diff against "$base"; running everything.',
    );
    return withTests;
  }

  final affected = AffectedPackages(workspace);
  if (affected.touchesEverything(changed)) {
    out.writeln(
      'test_runner: a workspace-wide file changed; running everything.',
    );
    return withTests;
  }
  return affected.forChanges(changed);
}

ArgParser _parser() => ArgParser()
  ..addOption('root', defaultsTo: '.', help: 'Workspace root.')
  ..addFlag(
    'affected',
    negatable: false,
    help: 'Select only the packages a change against --base can break.',
  )
  ..addOption(
    'base',
    defaultsTo: 'origin/main',
    help: 'What --affected diffs against.',
  )
  ..addMultiOption(
    'package',
    abbr: 'p',
    help: 'Run these packages by name, ignoring --affected.',
  )
  ..addOption('preset', defaultsTo: 'pr', help: 'The dart test preset.')
  ..addFlag(
    'bundle',
    negatable: false,
    help: "Compile each package's test files into one entrypoint.",
  )
  ..addFlag(
    'cache',
    defaultsTo: true,
    help: 'Skip a package whose sources have not moved since it last passed.',
  )
  ..addOption('bucket', defaultsTo: '0', help: "This machine's index.")
  ..addOption('total', defaultsTo: '1', help: 'How many machines there are.')
  ..addOption('concurrency', help: '-j for pure Dart packages.')
  ..addOption('junit', help: 'Write a JUnit XML report to this path.')
  ..addFlag(
    'list',
    negatable: false,
    help: 'Print the selection and stop.',
  )
  ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this usage.');

String _usage(ArgParser parser) =>
    '''
Usage: dart run tooling/test_runner/bin/test_runner.dart [options]

${parser.usage}

Exit codes: 0 clean, 1 a suite failed, 64 the runner could not run.''';
