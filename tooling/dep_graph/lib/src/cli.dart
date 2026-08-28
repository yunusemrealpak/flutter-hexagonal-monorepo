import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import 'model/dependency_graph.dart';
import 'render/document.dart';
import 'render/dot.dart';
import 'render/mermaid.dart';
import 'scanner.dart';
import 'type_matchers.dart';

/// Exit codes, kept distinct on purpose.
///
/// The same split `arch_check` makes and for the same reason: a tool that
/// exits 1 both for "the graph has a cycle" and for "I could not read my own
/// inputs" teaches CI to treat the second as the first.
abstract final class ExitCodes {
  /// The graph was produced and has no cycle.
  static const int clean = 0;

  /// The graph has a cycle, or `--check` found the file stale.
  static const int problem = 1;

  /// The tool could not run: bad arguments, missing rules, unreadable root.
  static const int misconfigured = 64;
}

/// Parses arguments, renders the graph, returns an exit code.
///
/// Nothing here calls `exit()`. The entrypoint does that, so a test can run the
/// whole command and read what it wrote instead of taking the process down.
int runCli(List<String> arguments, {required StringSink out, StringSink? err}) {
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
  if (!Directory(root).existsSync()) {
    errors.writeln('dep_graph: no such directory: $root');
    return ExitCodes.misconfigured;
  }

  final rulesPath = p.normalize(p.join(root, options.option('rules')));
  final TypeRules rules;
  try {
    rules = TypeRules.fromFile(rulesPath);
  } on FormatException catch (error) {
    errors.writeln('dep_graph: ${error.message}');
    return ExitCodes.misconfigured;
  }

  final graph = DependencyGraph(WorkspaceScanner(rules).scan(root));
  final format = options.option('format')!;
  final rendered = switch (format) {
    'markdown' => GraphDocument.render(graph),
    'mermaid' => Mermaid.typeGraph(graph),
    'dot' => Dot.render(graph),
    _ => null,
  };
  if (rendered == null) {
    errors
      ..writeln('dep_graph: unknown format "$format"')
      ..writeln(_usage(parser));
    return ExitCodes.misconfigured;
  }

  final cycles = graph.cycles();
  final target = File(p.normalize(p.join(root, options.option('out'))));

  if (options.flag('stdout')) {
    out.write(rendered);
    return _verdict(out, graph, cycles);
  }

  if (options.flag('check')) {
    final current = target.existsSync() ? target.readAsStringSync() : null;
    if (current != rendered) {
      errors
        ..writeln(
          'dep_graph: ${p.relative(target.path, from: root)} is stale.',
        )
        ..writeln(
          "Run 'dart run tooling/dep_graph/bin/dep_graph.dart' and commit "
          'the result together with the change that moved an edge.',
        );
      return ExitCodes.problem;
    }
    final shown = p.relative(target.path, from: root);
    out.writeln('dep_graph: $shown is current.');
    return _verdict(out, graph, cycles);
  }

  target.parent.createSync(recursive: true);
  target.writeAsStringSync(rendered);
  out.writeln(
    'dep_graph: wrote ${p.relative(target.path, from: root)} — '
    '${graph.nodes.length} packages, ${graph.runtimeEdges.length} edges.',
  );
  return _verdict(out, graph, cycles);
}

int _verdict(
  StringSink out,
  DependencyGraph graph,
  List<List<String>> cycles,
) {
  if (cycles.isEmpty) return ExitCodes.clean;
  out.writeln('dep_graph: ${cycles.length} cycle(s) in the graph:');
  for (final cycle in cycles) {
    out.writeln('  ${cycle.join(' -> ')} -> ${cycle.first}');
  }
  return ExitCodes.problem;
}

ArgParser _parser() => ArgParser()
  ..addOption(
    'root',
    defaultsTo: '.',
    help: 'Workspace root to read.',
  )
  ..addOption(
    'rules',
    defaultsTo: 'tooling/arch_check/rules.yaml',
    help: 'Where the package-type matchers are read from, relative to --root.',
  )
  ..addOption(
    'out',
    defaultsTo: 'docs/dependency-graph.md',
    help: 'File to write, relative to --root.',
  )
  ..addOption(
    'format',
    defaultsTo: 'markdown',
    allowed: ['markdown', 'mermaid', 'dot'],
    help: 'What to render.',
  )
  ..addFlag(
    'check',
    negatable: false,
    help: 'Do not write; fail when the file on disk differs from the render.',
  )
  ..addFlag(
    'stdout',
    negatable: false,
    help: 'Write the render to stdout instead of to a file.',
  )
  ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this usage.');

String _usage(ArgParser parser) =>
    '''
Usage: dart run tooling/dep_graph/bin/dep_graph.dart [options]

${parser.usage}

Exit codes: 0 clean, 1 a cycle or a stale file, 64 the tool could not run.''';
