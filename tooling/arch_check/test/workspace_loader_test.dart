@Tags(['unit'])
library;

import 'package:arch_check/arch_check.dart';
import 'package:test/test.dart';

import 'support/workspace_paths.dart';

void main() {
  late WorkspaceLoader loader;

  setUp(() {
    loader = WorkspaceLoader(RuleSet.fromFile(rulesPath));
  });

  group('discovery', () {
    test('finds every package under the roots and nothing else', () {
      final loaded = loader.load(fixture('clean'));
      expect(loaded.workspace.packages.map((package) => package.name), [
        'core_kernel',
        'core_ports',
        'shipments_api',
        'shipments_application',
        'shipments_infrastructure',
        'http_dio',
        'some_tool',
      ]);
    });

    test('reads no source from a package nested inside another', () {
      // This checker's fixtures are real mini workspaces under test/. Reading
      // them as arch_check's own sources reported every deliberate violation
      // in them as a violation of the workspace being checked — which is how
      // this rule was found.
      final loaded = loader.load(fixture('clean'));
      final index = SourceIndex(loaded.workspace);
      final kernel = loaded.workspace.byName('core_kernel')!;
      expect(
        index.of(kernel).all.map((file) => file.relativePath),
        everyElement(startsWith('packages/core/core_kernel/')),
      );
    });

    test('does not descend into a test directory', () {
      // This is what keeps a checker's own fixtures — real pubspecs in real
      // directories — out of a run against the workspace that contains them.
      final loaded = loader.load(packageRoot);
      expect(loaded.workspace.packages, isEmpty);
      expect(loaded.violations, isEmpty);
    });
  });

  group('type inference', () {
    test('derives a type from the path and the directory name', () {
      final loaded = loader.load(fixture('clean'));
      final types = {
        for (final package in loaded.workspace.packages)
          package.name: package.type,
      };
      expect(types, {
        'core_kernel': PackageType.coreKernel,
        'core_ports': PackageType.corePorts,
        'shipments_api': PackageType.featureApi,
        'shipments_application': PackageType.featureApplication,
        'shipments_infrastructure': PackageType.featureInfrastructure,
        'http_dio': PackageType.platform,
        'some_tool': PackageType.tooling,
      });
    });

    test('resolves the owning feature and its contract package', () {
      final loaded = loader.load(fixture('clean'));
      final application = loaded.workspace.byName('shipments_application')!;
      expect(application.owningFeature, 'shipments');
      expect(application.ownApiName, 'shipments_api');
    });

    test('leaves a package with no type out of the graph', () {
      final loaded = loader.load(fixture('unknown_type'));
      expect(loaded.workspace.packages, isEmpty);
      expect(loaded.violations.single.code, 'unknown_package_type');
    });
  });

  group('reading a pubspec', () {
    test('reads a build.yaml when there is one, and not otherwise', () {
      final loaded = loader.load(fixture('clean'));
      expect(
        loaded.workspace.byName('shipments_infrastructure')!.hasBuildConfig,
        isTrue,
      );
      expect(loaded.workspace.byName('core_kernel')!.hasBuildConfig, isFalse);
    });

    test('treats a name outside the workspace as third party', () {
      // pub is what makes this safe: a member depending on a product package
      // that does not exist fails to resolve long before this checker runs.
      final loaded = loader.load(fixture('clean'));
      expect(loaded.workspace.byName('dio'), isNull);
    });
  });
}
