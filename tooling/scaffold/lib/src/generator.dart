import 'dart:io';

import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as p;

import 'feature_plan.dart';
import 'templates.dart';
import 'workspace_registration.dart';

/// What a run of the scaffolder did, or would do.
final class ScaffoldResult {
  /// Creates the result.
  const ScaffoldResult({
    required this.plan,
    required this.created,
    required this.skipped,
    required this.registered,
    required this.dryRun,
  });

  /// The plan that was carried out.
  final FeaturePlan plan;

  /// Files written, relative to the workspace root, sorted.
  final List<String> created;

  /// Files that already existed and were left alone.
  final List<String> skipped;

  /// Package paths added to the root `workspace:` list.
  final List<String> registered;

  /// Whether anything was actually written.
  final bool dryRun;
}

/// Writes a feature's packages to disk.
final class Generator {
  /// Creates a generator rooted at [rootPath].
  const Generator({
    required this.rootPath,
    this.dryRun = false,
    this.force = false,
    this.codegen = false,
  });

  /// The workspace root.
  final String rootPath;

  /// When true, nothing is written and the result describes what would be.
  final bool dryRun;

  /// When true, an existing file is overwritten instead of skipped.
  ///
  /// Off by default, and the default is the important half: a scaffolder that
  /// silently overwrote a file would be a scaffolder nobody could re-run on a
  /// feature that already exists, which is exactly when someone reaches for it
  /// — to add the `_testing` package they skipped the first time.
  final bool force;

  /// When true, packages whose role conventionally generates code get a
  /// `build.yaml` and the matching dev dependencies.
  final bool codegen;

  /// Writes [plan], and registers its packages in the root pubspec.
  ScaffoldResult generate(FeaturePlan plan) {
    final created = <String>[];
    final skipped = <String>[];
    final formatter = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    );

    for (final package in plan.packages) {
      final files = filesFor(package, plan, codegen: codegen);
      for (final entry in files.entries) {
        final relative = p.posix.join(package.relativePath, entry.key);
        final absolute = p.join(rootPath, p.joinAll(p.posix.split(relative)));
        if (File(absolute).existsSync() && !force) {
          skipped.add(relative);
          continue;
        }
        created.add(relative);
        if (dryRun) continue;
        final content = entry.key.endsWith('.dart')
            ? formatter.format(entry.value)
            : entry.value;
        File(absolute)
          ..createSync(recursive: true)
          ..writeAsStringSync(content);
      }
    }

    created.sort();
    skipped.sort();

    final registration = WorkspaceRegistration(rootPath);
    final paths = plan.packages.map((package) => package.relativePath).toList();
    final alreadyThere = registration.read().toSet();
    final added = paths.where((path) => !alreadyThere.contains(path)).toList()
      ..sort();
    if (!dryRun && added.isNotEmpty) {
      final updated = registration.withPaths(paths);
      if (updated != null) registration.write(updated);
    }

    return ScaffoldResult(
      plan: plan,
      created: created,
      skipped: skipped,
      registered: added,
      dryRun: dryRun,
    );
  }
}
