import '../model/package_type.dart';
import '../model/violation.dart';
import '../model/workspace_package.dart';
import 'check.dart';

/// Section 2: every edge in a pubspec's `dependencies:` block is on the
/// whitelist for that package's type.
///
/// `dev_dependencies:` is deliberately out of scope — a test harness is not an
/// architectural dependency. What is in scope is a dev dependency that reached
/// `lib/`, which is the one way it stops being a test harness.
final class DependencyCheck implements Check {
  /// Creates the section 2 check.
  const DependencyCheck();

  @override
  String get name => 'dependency edges (section 2)';

  @override
  Iterable<Violation> run(CheckContext context) sync* {
    for (final package in context.workspace.packages) {
      yield* _edges(context, package);
      yield* _devDependencyImports(context, package);
    }
  }

  Iterable<Violation> _edges(
    CheckContext context,
    WorkspacePackage package,
  ) sync* {
    final policy = context.rules.policyFor(package.type);
    if (policy.allowsAnything) return;

    for (final dependency in package.dependencies) {
      if (dependency.isSdk) {
        if (policy.allowSdks.contains(dependency.sdk)) continue;
        yield Violation(
          code: 'forbidden_dependency',
          location: ViolationLocation(package: package.relativePath),
          what:
              '${package.name} (${package.type.id}) depends on the '
              '${dependency.sdk} SDK',
          remedy: context.rules.remedyFor('forbidden_dependency.sdk'),
        );
        continue;
      }

      final target = context.workspace.byName(dependency.name);
      if (target == null) {
        if (policy.allowThirdParty) continue;
        yield Violation(
          code: 'forbidden_dependency',
          location: ViolationLocation(package: package.relativePath),
          what:
              '${package.name} (${package.type.id}) depends on the '
              'third-party package ${dependency.name}',
          remedy: context.rules.remedyFor('forbidden_dependency.third_party'),
        );
        continue;
      }

      if (_allows(policy.allow, package, target)) continue;

      // A tool reaching into the product has its own code, because the reason
      // it is wrong is not the same reason a feature edge is wrong.
      if (package.type == PackageType.tooling &&
          target.type != PackageType.tooling) {
        yield Violation(
          code: 'tooling_depends_on_product',
          location: ViolationLocation(package: package.relativePath),
          what: '${package.name} depends on ${target.name}',
          remedy: context.rules.remedyFor('tooling_depends_on_product'),
        );
        continue;
      }

      yield Violation(
        code: 'forbidden_dependency',
        location: ViolationLocation(package: package.relativePath),
        what:
            '${package.name} (${package.type.id}) depends on '
            '${target.name} (${target.type.id})',
        remedy: _remedy(context, package, target),
      );
    }
  }

  bool _allows(
    Set<String> allow,
    WorkspacePackage package,
    WorkspacePackage target,
  ) {
    if (allow.contains(target.type.id)) return true;
    if (target.type != PackageType.featureApi) return false;
    final isOwn = package.ownApiName == target.name;
    return allow.contains(isOwn ? 'own_api' : 'foreign_api');
  }

  String _remedy(
    CheckContext context,
    WorkspacePackage package,
    WorkspacePackage target,
  ) {
    final isForeign =
        package.type.isFeature &&
        target.type.isFeature &&
        target.owningFeature != null &&
        target.owningFeature != package.owningFeature;
    if (!isForeign) return context.rules.remedyFor('forbidden_dependency');

    // Two different mistakes wear the same violation code, and telling a
    // developer to do what they already did is worse than saying nothing.
    //
    // Reaching past a contract into another feature's internals is fixed by
    // depending on that feature's _api instead. But the target here may
    // already *be* that _api — `_infrastructure` is not allowed to see a
    // foreign feature at all — and then the fix is not a different
    // dependency, it is a different layer doing the crossing.
    if (target.type == PackageType.featureApi) {
      return context.rules.remedyFor('forbidden_dependency.foreign_api');
    }
    return context.rules.remedyFor(
      'forbidden_dependency.foreign_feature',
      vars: {'foreign_api': '${target.owningFeature}_api'},
    );
  }

  /// Section 2.0: a package that imports a dev dependency from `lib/` has
  /// turned a build-time tool into a runtime dependency it never declared.
  Iterable<Violation> _devDependencyImports(
    CheckContext context,
    WorkspacePackage package,
  ) sync* {
    final declared = package.dependencies.map((d) => d.name).toSet()
      ..add(package.name);
    final dev = package.devDependencies
        .map((d) => d.name)
        .where((name) => !declared.contains(name))
        .toSet();
    if (dev.isEmpty) return;

    for (final file in context.sources.of(package).inDirectory('lib')) {
      for (final directive in file.uriDirectives) {
        final imported = _packageOf(directive.uri);
        if (imported == null || !dev.contains(imported)) continue;
        yield Violation(
          code: 'dev_dependency_in_lib',
          location: ViolationLocation(
            package: package.relativePath,
            file: file.relativePath,
            line: directive.line,
          ),
          what: "imports '${directive.uri}', and $imported is a dev dependency",
          remedy: context.rules.remedyFor('dev_dependency_in_lib'),
        );
      }
    }
  }
}

/// The package name in a `package:name/...` URI, or `null` for any other URI.
String? packageOfUri(String uri) => _packageOf(uri);

String? _packageOf(String uri) {
  const prefix = 'package:';
  if (!uri.startsWith(prefix)) return null;
  final rest = uri.substring(prefix.length);
  final slash = rest.indexOf('/');
  return slash == -1 ? rest : rest.substring(0, slash);
}
