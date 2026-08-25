@Tags(['unit'])
library;

import 'package:scaffold/scaffold.dart';
import 'package:test/test.dart';

/// The templates are checked for the properties that only break for some
/// feature names, because those are the ones a manual try-out misses: the
/// first feature anyone scaffolds is `billing`, and `billing_api` happens to
/// sort before `core_kernel`.
void main() {
  FeaturePlan planFor(String feature) => FeaturePlan.of(
    feature: feature,
    split: FeatureSplit.full,
    existingPackages: const {
      'core_kernel',
      'core_navigation',
      'core_ports',
      'core_testing',
      'design_system',
    },
    withTesting: true,
  );

  Map<String, String> filesOf(String feature, String packageName) {
    final plan = planFor(feature);
    final package = plan.packages.singleWhere((p) => p.name == packageName);
    return filesFor(package, plan, codegen: false);
  }

  // `faq_api` sorts after `core_kernel`; `billing_api` sorts before it. A
  // template that hard-codes either order is right for half the workspace.
  for (final feature in ['billing', 'faq']) {
    group('for a feature called $feature', () {
      test('package imports in a seed source are alphabetical', () {
        final source = filesOf(
          feature,
          '${feature}_application',
        )['lib/src/load_$feature.dart']!;
        final imports = source
            .split('\n')
            .where((line) => line.startsWith("import 'package:"))
            .toList();
        expect(imports, orderedEquals([...imports]..sort()));
      });

      test('pubspec dependencies are sorted', () {
        for (final package in planFor(feature).packages) {
          final pubspec = filesFor(
            package,
            planFor(feature),
            codegen: true,
          )['pubspec.yaml']!;
          expect(
            _sortedBlocks(pubspec),
            isTrue,
            reason: '${package.name} pubspec is not sorted:\n$pubspec',
          );
        }
      });

      test('every Dart and YAML line fits the 80-column limit', () {
        // Markdown is left out on purpose: prose in this repository is written
        // one paragraph per line and wrapped by the reader's editor, and
        // hard-wrapping it would make every documentation diff a reflow.
        for (final package in planFor(feature).packages) {
          final files = filesFor(package, planFor(feature), codegen: true);
          for (final entry in files.entries) {
            if (!entry.key.endsWith('.dart') && !entry.key.endsWith('.yaml')) {
              continue;
            }
            final tooLong = entry.value
                .split('\n')
                .where((line) => line.length > 80)
                .toList();
            expect(
              tooLong,
              isEmpty,
              reason: '${package.name}/${entry.key}: ${tooLong.join('\n')}',
            );
          }
        }
      });
    });
  }

  group('the barrel', () {
    test('exports exactly the seed sources, in sorted order', () {
      final files = filesOf('billing', 'billing_infrastructure');
      final sources =
          files.keys
              .where((path) => path.startsWith('lib/src/'))
              .map((path) => path.substring('lib/'.length))
              .toList()
            ..sort();
      final barrel = files['lib/billing_infrastructure.dart']!;
      final exported = barrel
          .split('\n')
          .where((line) => line.startsWith('export '))
          .map((line) => line.substring("export '".length, line.length - 2))
          .toList();
      expect(exported, sources);
    });
  });

  group('build.yaml', () {
    test('is absent without --codegen and narrowed with it', () {
      final plan = planFor('billing');
      final api = plan.packages.singleWhere((p) => p.name == 'billing_api');
      expect(
        filesFor(api, plan, codegen: false),
        isNot(contains('build.yaml')),
      );
      final withCodegen = filesFor(api, plan, codegen: true)['build.yaml']!;
      expect(withCodegen, contains('enabled: true'));
      expect(withCodegen, contains('generate_for:'));
    });

    test('never enables json_serializable in an _api package', () {
      // Rule G2. arch_check would catch it, but a scaffolder that generated
      // the violation would make the checker a nuisance rather than a guide.
      final plan = planFor('billing');
      final api = plan.packages.singleWhere((p) => p.name == 'billing_api');
      expect(
        filesFor(api, plan, codegen: true)['build.yaml'],
        isNot(contains('json_serializable:')),
      );
    });
  });
}

/// Whether every dependency block in a pubspec is alphabetically ordered.
bool _sortedBlocks(String pubspec) {
  final lines = pubspec.split('\n');
  for (final header in ['dependencies:', 'dev_dependencies:']) {
    final start = lines.indexOf(header);
    if (start == -1) continue;
    final names = <String>[];
    for (var i = start + 1; i < lines.length; i++) {
      final line = lines[i];
      if (!line.startsWith('  ') || line.trim().isEmpty) break;
      if (line.startsWith('    ')) continue;
      names.add(line.trim().split(':').first);
    }
    final sorted = [...names]..sort();
    for (var i = 0; i < names.length; i++) {
      if (names[i] != sorted[i]) return false;
    }
  }
  return true;
}
