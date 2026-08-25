@Tags(['unit'])
library;

import 'package:scaffold/scaffold.dart';
import 'package:test/test.dart';

/// The plan is where the constitution is encoded, so this is where it is
/// asserted. Every expectation below is a row of section 2 of
/// `docs/DEPENDENCY_RULES.md` written out; if the document changes and this
/// file does not, one of the two is wrong.
void main() {
  const workspace = {
    'core_kernel',
    'core_navigation',
    'core_ports',
    'core_testing',
    'design_system',
  };

  FeaturePlan planFor(
    FeatureSplit split, {
    Set<String> existing = workspace,
    List<String> variants = const [''],
    bool withTesting = false,
  }) => FeaturePlan.of(
    feature: 'billing',
    split: split,
    existingPackages: existing,
    presentationVariants: variants,
    withTesting: withTesting,
  );

  List<String> dependenciesOf(FeaturePlan plan, String name) =>
      plan.packages.singleWhere((package) => package.name == name).dependencies;

  group('which packages a split produces', () {
    test(
      'the full split is api, application, infrastructure, presentation',
      () {
        expect(planFor(FeatureSplit.full).packages.map((p) => p.name), [
          'billing_api',
          'billing_application',
          'billing_infrastructure',
          'billing_presentation',
        ]);
      },
    );

    test('the reduced split merges application and infrastructure', () {
      expect(planFor(FeatureSplit.reduced).packages.map((p) => p.name), [
        'billing_api',
        'billing_core',
        'billing_presentation',
      ]);
    });

    test('_api is separate in both, because it resolves the cycles', () {
      for (final split in FeatureSplit.values) {
        expect(
          planFor(split).packages.map((p) => p.name),
          contains('billing_api'),
        );
      }
    });

    test('_testing is opt-in', () {
      expect(
        planFor(FeatureSplit.full).packages.map((p) => p.name),
        isNot(contains('billing_testing')),
      );
      expect(
        planFor(
          FeatureSplit.full,
          withTesting: true,
        ).packages.map((p) => p.name),
        contains('billing_testing'),
      );
    });

    test('a feature can ship one presentation package per app', () {
      final plan = planFor(
        FeatureSplit.full,
        variants: ['courier', 'dispatcher'],
      );
      expect(
        plan.packages.map((p) => p.name),
        containsAll([
          'billing_presentation_courier',
          'billing_presentation_dispatcher',
        ]),
      );
    });
  });

  group('what each package may depend on', () {
    late FeaturePlan full;
    late FeaturePlan reduced;

    setUp(() {
      full = planFor(FeatureSplit.full, withTesting: true);
      reduced = planFor(FeatureSplit.reduced);
    });

    test(
      '_api: core_kernel and core_ports, and nothing of its own feature',
      () {
        expect(dependenciesOf(full, 'billing_api'), [
          'core_kernel',
          'core_ports',
        ]);
      },
    );

    test(
      '_application: own _api and the core packages, never a platform one',
      () {
        expect(dependenciesOf(full, 'billing_application'), [
          'billing_api',
          'core_kernel',
          'core_ports',
        ]);
      },
    );

    test('_infrastructure: own _api only, never a foreign one', () {
      expect(dependenciesOf(full, 'billing_infrastructure'), [
        'billing_api',
        'core_kernel',
        'core_ports',
      ]);
    });

    test('_presentation: own _api, navigation and the design system', () {
      expect(dependenciesOf(full, 'billing_presentation'), [
        'billing_api',
        'core_kernel',
        'core_navigation',
        'design_system',
      ]);
    });

    test('_presentation does not reach for core_ports', () {
      // Not an oversight in the table: a screen asks a use case, and the use
      // case is what holds a capability.
      expect(
        dependenciesOf(full, 'billing_presentation'),
        isNot(contains('core_ports')),
      );
    });

    test('_testing: contracts only', () {
      expect(dependenciesOf(full, 'billing_testing'), [
        'billing_api',
        'core_kernel',
        'core_ports',
        'core_testing',
      ]);
    });

    test('_core: what application and infrastructure would each have had', () {
      expect(dependenciesOf(reduced, 'billing_core'), [
        'billing_api',
        'core_kernel',
        'core_ports',
      ]);
    });

    test('only presentation binds the Flutter SDK', () {
      final flutterPackages = full.packages
          .where((package) => package.usesFlutter)
          .map((package) => package.name);
      expect(flutterPackages, ['billing_presentation']);
    });
  });

  group('a dependency that does not exist yet', () {
    test('is left out rather than written into an unresolvable pubspec', () {
      // design_system arrives in a later phase. A presentation package
      // generated before then still has to run `dart pub get`.
      final plan = planFor(
        FeatureSplit.full,
        existing: const {'core_kernel', 'core_ports'},
      );
      expect(dependenciesOf(plan, 'billing_presentation'), [
        'billing_api',
        'core_kernel',
      ]);
    });
  });

  group('paths', () {
    test('every package sits under its feature directory', () {
      for (final package in planFor(
        FeatureSplit.full,
        withTesting: true,
      ).packages) {
        expect(
          package.relativePath,
          'packages/features/billing/${package.name}',
        );
      }
    });
  });
}
