@Tags(['unit'])
library;

import 'dart:io';

import 'package:dep_graph/dep_graph.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'support/paths.dart';

/// Runs the command and hands back what it wrote and what it returned.
({int code, String out, String err}) run(List<String> arguments) {
  final out = StringBuffer();
  final err = StringBuffer();
  final code = runCli(arguments, out: out, err: err);
  return (code: code, out: out.toString(), err: err.toString());
}

void main() {
  late Directory workspace;

  setUp(() {
    // A copy, because two of these tests write into the workspace they read.
    workspace = Directory.systemTemp.createTempSync('dep_graph_cli');
    _copy(Directory(fixture('tiny')), workspace);
  });

  tearDown(() => workspace.deleteSync(recursive: true));

  test('writes the document and reports what it drew', () {
    final result = run([
      '--root=${workspace.path}',
      '--rules=rules.yaml',
      '--out=docs/dependency-graph.md',
    ]);

    expect(result.code, ExitCodes.clean);
    expect(result.out, contains('4 packages'));
    expect(
      File(p.join(workspace.path, 'docs', 'dependency-graph.md')).existsSync(),
      isTrue,
    );
  });

  test('--check passes on a file it just wrote', () {
    run(['--root=${workspace.path}', '--rules=rules.yaml']);

    final result = run([
      '--root=${workspace.path}',
      '--rules=rules.yaml',
      '--check',
    ]);

    expect(result.code, ExitCodes.clean);
    expect(result.out, contains('is current'));
  });

  test('--check fails on a stale file and says what to run', () {
    final target = File(p.join(workspace.path, 'docs', 'dependency-graph.md'))
      ..createSync(recursive: true)
      ..writeAsStringSync('# out of date\n');

    final result = run([
      '--root=${workspace.path}',
      '--rules=rules.yaml',
      '--check',
    ]);

    expect(result.code, ExitCodes.problem);
    expect(result.err, contains('is stale'));
    expect(result.err, contains('dart run tooling/dep_graph'));
    expect(target.readAsStringSync(), '# out of date\n');
  });

  test('a cycle is exit 1, with the loop named', () {
    final result = run([
      '--root=${fixture('cycle')}',
      '--rules=rules.yaml',
      '--stdout',
    ]);

    expect(result.code, ExitCodes.problem);
    expect(result.out, contains('alpha_api -> beta_api -> alpha_api'));
  });

  test('--stdout writes nothing to disk', () {
    final result = run([
      '--root=${workspace.path}',
      '--rules=rules.yaml',
      '--stdout',
      '--format=dot',
    ]);

    expect(result.code, ExitCodes.clean);
    expect(result.out, contains('digraph peyk {'));
    expect(
      File(p.join(workspace.path, 'docs', 'dependency-graph.md')).existsSync(),
      isFalse,
    );
  });

  test('a missing rule file is 64, not 1', () {
    // The split the exit codes exist for: "the graph has a cycle" and "I could
    // not read my own inputs" are different failures, and a CI that cannot
    // tell them apart treats the second as the first.
    final result = run([
      '--root=${workspace.path}',
      '--rules=nowhere.yaml',
    ]);

    expect(result.code, ExitCodes.misconfigured);
    expect(result.err, contains('no rule file'));
  });

  test('an unknown format is 64', () {
    final result = run([
      '--root=${workspace.path}',
      '--rules=rules.yaml',
      '--format=svg',
    ]);

    expect(result.code, ExitCodes.misconfigured);
  });

  test('a root that does not exist is 64', () {
    final result = run(['--root=${p.join(workspace.path, 'nope')}']);

    expect(result.code, ExitCodes.misconfigured);
    expect(result.err, contains('no such directory'));
  });
}

void _copy(Directory from, Directory to) {
  for (final entity in from.listSync(recursive: true)) {
    final relative = p.relative(entity.path, from: from.path);
    final target = p.join(to.path, relative);
    if (entity is Directory) {
      Directory(target).createSync(recursive: true);
    } else if (entity is File) {
      Directory(p.dirname(target)).createSync(recursive: true);
      entity.copySync(target);
    }
  }
}
