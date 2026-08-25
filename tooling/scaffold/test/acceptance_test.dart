@Tags(['unit'])
library;

import 'dart:io';

import 'package:scaffold/scaffold.dart';
import 'package:test/test.dart';

import 'support/repository_paths.dart';
import 'support/temp_workspace.dart';

/// The acceptance criterion for this package, and the reason it exists.
///
/// A scaffolder whose output violates the constitution is worse than no
/// scaffolder: it teaches the rules wrong and it makes arch_check look like a
/// nuisance. So the test generates a feature into a throwaway workspace and
/// runs the real checker over it, as a subprocess, with the real rule file.
///
/// A subprocess rather than an import, because rule I7 is about tools too:
/// this package depends on nothing but third-party Dart, arch_check included.
void main() {
  late TempWorkspace workspace;

  setUp(() => workspace = TempWorkspace.create());
  tearDown(() => workspace.dispose());

  void generate({
    required FeatureSplit split,
    bool withTesting = false,
    bool codegen = false,
    List<String> variants = const [''],
    String feature = 'billing',
  }) {
    final plan = FeaturePlan.of(
      feature: feature,
      split: split,
      existingPackages: WorkspaceRegistration(
        workspace.root,
      ).registeredPackageNames(),
      presentationVariants: variants,
      withTesting: withTesting,
    );
    Generator(rootPath: workspace.root, codegen: codegen).generate(plan);
  }

  String archCheck() {
    final result = Process.runSync('dart', [
      'run',
      archCheckBin,
      '--root=${workspace.root}',
      '--rules=$archCheckRules',
    ], workingDirectory: repositoryRoot);
    return '${result.stdout}${result.stderr}';
  }

  test('a full-split feature passes arch_check', () {
    generate(split: FeatureSplit.full, withTesting: true);
    expect(archCheck(), contains('no violations'));
  });

  test('a reduced-split feature passes arch_check', () {
    generate(split: FeatureSplit.reduced, feature: 'faq');
    expect(archCheck(), contains('no violations'));
  });

  test('a feature with two presentation packages passes arch_check', () {
    // The one shape that exercises `name_contains` type inference rather than
    // a suffix match, and the one where a feature owns more than one package
    // of the same role.
    generate(
      split: FeatureSplit.full,
      feature: 'shipments',
      variants: ['courier', 'dispatcher'],
    );
    expect(archCheck(), contains('no violations'));
  });

  test('--codegen output passes arch_check too', () {
    // Including rule G2: the _api package gets freezed and never
    // json_serializable, and rule G4's build.yaml shape.
    generate(split: FeatureSplit.full, codegen: true);
    expect(archCheck(), contains('no violations'));
  });

  test('a feature whose name sorts after core_kernel passes too', () {
    // `faq_api` sorts after `core_kernel` and `billing_api` before it. Half
    // the ordering bugs in a template only appear on one side of that line.
    generate(split: FeatureSplit.full, feature: 'faq', withTesting: true);
    expect(archCheck(), contains('no violations'));
  });
}
