import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import 'report.dart';
import 'rules/rule_set.dart';
import 'runner.dart';

/// Exit codes, kept distinct on purpose.
///
/// A checker that exits 1 both for "the architecture is broken" and for "I
/// could not read my own rules" teaches CI to treat the second as the first.
abstract final class ExitCodes {
  /// No violations.
  static const int clean = 0;

  /// At least one violation.
  static const int violations = 1;

  /// The checker could not run: bad arguments, or an unreadable rule file.
  static const int misconfigured = 64;
}

/// Parses arguments, runs the checker, prints the report, returns an exit code.
///
/// Nothing here calls `exit()`. The entrypoint does that, so a test can run the
/// whole command and inspect what it wrote instead of taking the process down.
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
    errors.writeln('arch_check: no such directory: $root');
    return ExitCodes.misconfigured;
  }

  final format = ReportFormat.byId(options.option('format')!);
  if (format == null) {
    errors
      ..writeln('arch_check: unknown format "${options.option('format')}"')
      ..writeln(_usage(parser));
    return ExitCodes.misconfigured;
  }

  final rulesPath = p.normalize(p.absolute(options.option('rules')!));
  final ArchCheck checker;
  try {
    checker = ArchCheck.fromRulesFile(rulesPath);
  } on RuleSetException catch (error) {
    errors.writeln('arch_check: $error');
    return ExitCodes.misconfigured;
  }

  final run = checker.run(root);
  out.writeln(render(run, format));
  return run.isClean ? ExitCodes.clean : ExitCodes.violations;
}

ArgParser _parser() => ArgParser()
  ..addOption(
    'root',
    defaultsTo: '.',
    help: 'Workspace root to check.',
    valueHelp: 'dir',
  )
  ..addOption(
    'rules',
    defaultsTo: 'tooling/arch_check/rules.yaml',
    help: 'The rule file to enforce.',
    valueHelp: 'file',
  )
  ..addOption(
    'format',
    defaultsTo: 'text',
    allowed: ['text', 'json'],
    help: 'Report format.',
  )
  ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this usage.');

String _usage(ArgParser parser) =>
    '''
Enforces the dependency constitution in docs/DEPENDENCY_RULES.md.

Usage: dart run tooling/arch_check/bin/arch_check.dart [options]

${parser.usage}

Exit codes: ${ExitCodes.clean} clean, ${ExitCodes.violations} violations found, ${ExitCodes.misconfigured} could not run.''';
