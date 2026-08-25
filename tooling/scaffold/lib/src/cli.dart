import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import 'feature_plan.dart';
import 'generator.dart';
import 'naming.dart';
import 'workspace_registration.dart';

/// Exit codes, kept distinct for the same reason arch_check keeps them
/// distinct: "you asked for something impossible" and "I wrote the files" must
/// not look the same to a script.
abstract final class ExitCodes {
  /// The feature was generated, or the dry run completed.
  static const int ok = 0;

  /// Bad arguments, or a workspace the scaffolder cannot write into.
  static const int misconfigured = 64;
}

/// Parses arguments, generates the feature, prints what happened.
///
/// Nothing here calls `exit()`. The entrypoint does, so a test can run the
/// whole command and read what it wrote.
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

  if (options.flag('help') || options.command == null) {
    out.writeln(_usage(parser));
    return options.flag('help') ? ExitCodes.ok : ExitCodes.misconfigured;
  }

  final command = options.command!;
  if (command.name != 'new-feature') {
    errors.writeln(_usage(parser));
    return ExitCodes.misconfigured;
  }

  final name = command.option('name');
  if (name == null || !Naming.isValidFeatureName(name)) {
    errors.writeln(
      'scaffold: --name must be lower_snake_case and start with a letter; '
      'got "${name ?? ''}".',
    );
    return ExitCodes.misconfigured;
  }

  final split = FeatureSplit.byId(command.option('split')!);
  if (split == null) {
    errors.writeln('scaffold: unknown split "${command.option('split')}"');
    return ExitCodes.misconfigured;
  }

  final root = p.normalize(p.absolute(command.option('root')!));
  if (!Directory(root).existsSync()) {
    errors.writeln('scaffold: no such directory: $root');
    return ExitCodes.misconfigured;
  }

  final variants = command.multiOption('presentation');
  for (final variant in variants) {
    if (!Naming.isValidFeatureName(variant)) {
      errors.writeln(
        'scaffold: --presentation takes lower_snake_case names; '
        'got "$variant".',
      );
      return ExitCodes.misconfigured;
    }
  }

  final WorkspaceRegistration registration;
  final Set<String> existing;
  try {
    registration = WorkspaceRegistration(root);
    existing = registration.registeredPackageNames();
  } on WorkspaceRegistrationException catch (error) {
    errors.writeln('scaffold: $error');
    return ExitCodes.misconfigured;
  }

  final plan = FeaturePlan.of(
    feature: name,
    split: split,
    existingPackages: existing,
    presentationVariants: variants.isEmpty ? const [''] : variants,
    withTesting: command.flag('with-testing'),
  );

  final result = Generator(
    rootPath: root,
    dryRun: command.flag('dry-run'),
    force: command.flag('force'),
    codegen: command.flag('codegen'),
  ).generate(plan);

  _report(result, out: out, existing: existing);
  return ExitCodes.ok;
}

void _report(
  ScaffoldResult result, {
  required StringSink out,
  required Set<String> existing,
}) {
  final verb = result.dryRun ? 'would create' : 'created';
  out.writeln(
    'scaffold: $verb ${result.created.length} file(s) in '
    '${result.plan.packages.length} package(s) for '
    '${result.plan.feature} (${result.plan.split.id} split).',
  );

  for (final package in result.plan.packages) {
    final files = result.created
        .where((path) => path.startsWith('${package.relativePath}/'))
        .length;
    out.writeln('  ${package.relativePath}  ($files files)');
  }

  if (result.skipped.isNotEmpty) {
    out
      ..writeln()
      ..writeln(
        '${result.skipped.length} file(s) already existed and were left '
        'alone. Pass --force to overwrite them.',
      );
  }

  if (result.registered.isNotEmpty) {
    final noun = result.registered.length == 1 ? 'entry' : 'entries';
    out
      ..writeln()
      ..writeln(
        '${result.dryRun ? 'Would add' : 'Added'} '
        '${result.registered.length} $noun to the root workspace: list.',
      );
  }

  // A dependency that does not exist yet is left out of the pubspec rather
  // than written into one that cannot resolve. Saying which one, and when to
  // add it, is the difference between a deliberate omission and a bug.
  if (!existing.contains('design_system')) {
    out
      ..writeln()
      ..writeln(
        'design_system is not in this workspace yet, so the presentation '
        'package does not depend on it. Add it when the design packages '
        'land.',
      );
  }

  out
    ..writeln()
    ..writeln('Next:')
    ..writeln('  dart pub get')
    ..writeln('  dart run melos run analyze')
    ..writeln('  dart run melos run arch:check')
    ..writeln('  dart test ${result.plan.packages.first.relativePath}');
}

ArgParser _parser() {
  final newFeature = ArgParser()
    ..addOption(
      'name',
      help: 'The feature, in lower_snake_case.',
      valueHelp: 'name',
    )
    ..addOption(
      'split',
      defaultsTo: 'full',
      allowed: ['full', 'reduced'],
      help:
          'full: _api, _application, _infrastructure, _presentation. '
          'reduced: _api, _core, _presentation.',
    )
    ..addMultiOption(
      'presentation',
      help:
          'One presentation package per value, suffixed with it. '
          'Omit for a single <feature>_presentation.',
      valueHelp: 'courier,dispatcher',
    )
    ..addFlag(
      'with-testing',
      negatable: false,
      help:
          'Also create <feature>_testing. Create it only when another '
          "package's tests will consume its fakes.",
    )
    ..addFlag(
      'codegen',
      negatable: false,
      help:
          'Write a build.yaml and the matching dev dependencies for the '
          'roles that conventionally generate. Off by default: a package '
          'with no generated files has no build.yaml, and that is the '
          'cheapest configuration rather than a missing one.',
    )
    ..addOption(
      'root',
      defaultsTo: '.',
      help: 'Workspace root.',
      valueHelp: 'dir',
    )
    ..addFlag(
      'dry-run',
      negatable: false,
      help: 'Write nothing; list what would be written.',
    )
    ..addFlag(
      'force',
      negatable: false,
      help: 'Overwrite files that already exist.',
    );

  return ArgParser()
    ..addCommand('new-feature', newFeature)
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this usage.');
}

String _usage(ArgParser parser) =>
    '''
Generates a feature's package skeleton, with the dependency lists the
constitution allows and nothing more.

Usage: dart run tooling/scaffold/bin/scaffold.dart new-feature --name <name> [options]

${parser.commands['new-feature']!.usage}

Choosing a split: the full split is for a feature with real business rules,
more than one outbound adapter, or offline behaviour. The reduced split is the
starting point for a narrow one. `_api` is separate either way, because it is
the only thing that resolves cycles and narrows the blast radius of a change.''';
