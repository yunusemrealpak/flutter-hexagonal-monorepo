import 'package:yaml/yaml.dart';

import '../model/violation.dart';
import '../model/workspace_package.dart';
import 'check.dart';

/// Section 6: the code generation rules that a machine can check.
///
/// Three of the four are about what a `build.yaml` says. The fourth, G1, is
/// about a package that must not have one at all.
final class CodegenCheck implements Check {
  /// Creates the section 6 check.
  const CodegenCheck();

  @override
  String get name => 'code generation (section 6)';

  @override
  Iterable<Violation> run(CheckContext context) sync* {
    for (final package in context.workspace.packages) {
      yield* _noCodegen(context, package);
      yield* _bannedBuilders(context, package);
      yield* _pinnedBuilders(context, package);
    }
  }

  /// G1. The innermost ring carries no generated file, no build.yaml and no
  /// build_runner dependency: a regeneration here is a regeneration
  /// everywhere.
  Iterable<Violation> _noCodegen(
    CheckContext context,
    WorkspacePackage package,
  ) sync* {
    final codegen = context.rules.codegen;
    if (!codegen.noCodegenTypes.contains(package.type)) return;

    for (final file in context.sources.of(package).all) {
      if (!codegen.isGenerated(file.fileName)) continue;
      yield Violation(
        code: codegen.noCodegenCode,
        location: ViolationLocation(
          package: package.relativePath,
          file: file.relativePath,
        ),
        what: '${file.fileName} is a generated file',
        remedy: context.rules.remedyFor(codegen.noCodegenCode),
      );
    }

    if (package.hasBuildConfig) {
      yield Violation(
        code: codegen.noCodegenCode,
        location: ViolationLocation(
          package: package.relativePath,
          file: '${package.relativePath}/build.yaml',
        ),
        what: '${package.name} has a build.yaml',
        remedy: context.rules.remedyFor(codegen.noCodegenCode),
      );
    }

    final hasBuildRunner = package.devDependencies.any(
      (dependency) => dependency.name == 'build_runner',
    );
    if (hasBuildRunner) {
      yield Violation(
        code: codegen.noCodegenCode,
        location: ViolationLocation(
          package: package.relativePath,
          file: '${package.relativePath}/pubspec.yaml',
        ),
        what: '${package.name} depends on build_runner',
        remedy: context.rules.remedyFor(codegen.noCodegenCode),
      );
    }
  }

  /// G2 and G3. A banned builder is caught in two places, because either one
  /// alone can be true while the other is false: enabled in build.yaml, or
  /// merely present as a dependency and therefore enabled by default.
  Iterable<Violation> _bannedBuilders(
    CheckContext context,
    WorkspacePackage package,
  ) sync* {
    for (final banned in context.rules.codegen.bannedBuilders) {
      if (!banned.types.contains(package.type)) continue;

      final enabled = _enabledBuilders(package.buildConfig);
      if (enabled.contains(banned.builder)) {
        yield Violation(
          code: banned.code,
          location: ViolationLocation(
            package: package.relativePath,
            file: '${package.relativePath}/build.yaml',
          ),
          what: 'build.yaml enables the ${banned.builder} builder',
          remedy: context.rules.remedyFor(banned.code),
        );
      }

      final declared = [
        ...package.dependencies,
        ...package.devDependencies,
      ].map((dependency) => dependency.name).contains(banned.builder);
      if (declared) {
        yield Violation(
          code: banned.code,
          location: ViolationLocation(
            package: package.relativePath,
            file: '${package.relativePath}/pubspec.yaml',
          ),
          what: '${package.name} depends on ${banned.builder}',
          remedy: context.rules.remedyFor(banned.code),
        );
      }
    }
  }

  /// G4. A package with generated files says which builders produce them and
  /// narrows each with `generate_for`. Without the narrowing build_runner
  /// offers every file in the package to the builder; across 75 packages that
  /// is the difference between a codegen run measured in seconds and one
  /// measured in minutes.
  Iterable<Violation> _pinnedBuilders(
    CheckContext context,
    WorkspacePackage package,
  ) sync* {
    final codegen = context.rules.codegen;
    if (codegen.noCodegenTypes.contains(package.type)) return;

    final generated = context.sources
        .of(package)
        .inDirectory('lib')
        .where((file) => codegen.isGenerated(file.fileName))
        .toList();
    if (generated.isEmpty) return;

    if (!package.hasBuildConfig) {
      yield Violation(
        code: codegen.pinnedBuildersCode,
        location: ViolationLocation(package: package.relativePath),
        what:
            '${generated.length} generated file(s) but no build.yaml, so '
            'every builder in the workspace is offered every file here',
        remedy: context.rules.remedyFor(codegen.pinnedBuildersCode),
      );
      return;
    }

    final enabled = _enabledBuilders(package.buildConfig);
    if (enabled.isEmpty) {
      yield Violation(
        code: codegen.pinnedBuildersCode,
        location: ViolationLocation(
          package: package.relativePath,
          file: '${package.relativePath}/build.yaml',
        ),
        what:
            'build.yaml enables no builder, yet the package has '
            '${generated.length} generated file(s)',
        remedy: context.rules.remedyFor(codegen.pinnedBuildersCode),
      );
      return;
    }

    if (!codegen.requireGenerateFor) return;
    for (final builder in enabled) {
      if (_hasGenerateFor(package.buildConfig, builder)) continue;
      yield Violation(
        code: codegen.pinnedBuildersCode,
        location: ViolationLocation(
          package: package.relativePath,
          file: '${package.relativePath}/build.yaml',
        ),
        what: 'the $builder builder is enabled without a generate_for glob',
        remedy: context.rules.remedyFor(codegen.pinnedBuildersCode),
      );
    }
  }

  /// The builders a build.yaml turns on, by their short name.
  ///
  /// A key may be written `json_serializable` or
  /// `json_serializable:json_serializable`; both name the same builder and the
  /// part before the colon is the package it comes from.
  Set<String> _enabledBuilders(YamlMap? config) {
    final enabled = <String>{};
    for (final target in _targets(config)) {
      final builders = target['builders'];
      if (builders is! YamlMap) continue;
      for (final entry in builders.entries) {
        final options = entry.value;
        if (options is YamlMap && options['enabled'] != true) continue;
        if (options is! YamlMap) continue;
        enabled.add(_builderName(entry.key.toString()));
      }
    }
    return enabled;
  }

  bool _hasGenerateFor(YamlMap? config, String builder) {
    for (final target in _targets(config)) {
      final builders = target['builders'];
      if (builders is! YamlMap) continue;
      for (final entry in builders.entries) {
        if (_builderName(entry.key.toString()) != builder) continue;
        final options = entry.value;
        if (options is YamlMap && options['generate_for'] != null) return true;
      }
    }
    return false;
  }

  Iterable<YamlMap> _targets(YamlMap? config) sync* {
    final targets = config?['targets'];
    if (targets is! YamlMap) return;
    for (final target in targets.values) {
      if (target is YamlMap) yield target;
    }
  }

  String _builderName(String key) {
    final colon = key.indexOf(':');
    return colon == -1 ? key : key.substring(colon + 1);
  }
}
