@Tags(['unit'])
library;

import 'package:arch_check/arch_check.dart';
import 'package:test/test.dart';

import 'support/workspace_paths.dart';

/// Every rule is proved by a fixture, and every fixture is a workspace that
/// could exist. Section 9 of `docs/DEPENDENCY_RULES.md` is what this file
/// enforces: a rule with no fixture is a rule that will silently stop working.
///
/// Each test asserts the *exact* multiset of codes the fixture produces, not
/// merely that the code it targets is present. Asserting containment would let
/// a rule start firing everywhere and still pass, and a checker that cries
/// wolf is worked around within a week.
void main() {
  late ArchCheck checker;

  setUp(() {
    checker = ArchCheck.fromRulesFile(rulesPath);
  });

  Map<String, int> codesIn(String name) =>
      checker.run(fixture(name)).countsByCode;

  group('the clean fixture', () {
    test('reports nothing, so every other fixture measures a real rule', () {
      final run = checker.run(fixture('clean'));
      expect(
        run.violations,
        isEmpty,
        reason: run.violations.map((v) => '$v').join('\n'),
      );
      expect(run.packagesChecked, 7);
    });

    test('exempts tooling from the ambient-API rules', () {
      // some_tool calls print(). Section 5 exempts apps and tooling; if that
      // exemption ever disappears, the clean fixture stops being clean and
      // this test says which rule did it.
      final run = checker.run(fixture('clean'));
      expect(run.countsByCode.keys, isNot(contains('ambient_print')));
    });
  });

  group('section 2, dependency edges', () {
    test('catches every forbidden edge and nothing else', () {
      expect(codesIn('broken_dependencies'), {
        'dev_dependency_in_lib': 1,
        'forbidden_dependency': 3,
        'tooling_depends_on_product': 1,
      });
    });

    test('names the contract package a feature should have used', () {
      final run = checker.run(fixture('broken_dependencies'));
      final crossing = run.violations.singleWhere(
        (violation) => violation.what.contains('shipments_application'),
      );
      expect(crossing.remedy, contains('shipments_api'));
    });
  });

  group('section 3, structure', () {
    test('catches every structural rule except the cycle', () {
      expect(codesIn('broken_structure'), {
        'barrel_leak': 2,
        'deep_import': 1,
        'implementation_in_api': 2,
        'missing_barrel': 1,
        'name_mismatch': 1,
        'stray_lib_file': 1,
        'unregistered_package': 2,
      });
    });

    test('still types a package whose pubspec name is wrong', () {
      // The directory is shipments_api and the pubspec says
      // shipments_contract. Believing the pubspec would drop the package out
      // of every type and hide the seven violations above behind one.
      final run = checker.run(fixture('broken_structure'));
      expect(run.countsByCode.keys, isNot(contains('unknown_package_type')));
    });
  });

  group('section 1, package types', () {
    test('a package that resolves to no type is itself a violation', () {
      final run = checker.run(fixture('unknown_type'));
      expect(run.countsByCode, {'unknown_package_type': 1});
      expect(run.packagesChecked, 0);
    });
  });
}
