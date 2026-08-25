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

  group('S7, cycles', () {
    test('reports one cycle once, as a path', () {
      final run = checker.run(fixture('broken_cycle'));
      expect(run.countsByCode, {'dependency_cycle': 1});
      expect(
        run.violations.single.what,
        'these packages form a cycle: payments_api -> shipments_api -> '
        'payments_api',
      );
    });
  });

  group('section 4, forbidden imports', () {
    test('catches each import in the package type that forbids it', () {
      expect(codesIn('broken_imports'), {
        'annotation_di_outside_app': 1,
        'flutter_in_pure_dart': 1,
        'forbidden_dependency': 2,
        'kernel_dependency': 1,
        'locator_outside_app': 1,
        'serialization_in_api': 1,
        'technology_in_domain': 1,
      });
    });
  });

  group('section 5, forbidden APIs', () {
    test('catches the four ambient calls and the throw', () {
      expect(codesIn('broken_apis'), {
        'ambient_clock': 1,
        'ambient_id': 1,
        'ambient_print': 2,
        'ambient_random': 1,
        'exception_at_port_boundary': 1,
      });
    });

    test('ignores the same calls when they appear in a doc comment', () {
      // The fixture's class is documented with the very calls it makes, and
      // core_ports documents `Clock` the same way. A text-scanning checker
      // reports the packages most careful about the rule the loudest, which
      // is why these rules are matched against the AST.
      final run = checker.run(fixture('broken_apis'));
      final clockHits = run.violations.where(
        (violation) => violation.code == 'ambient_clock',
      );
      expect(clockHits, hasLength(1));
      expect(clockHits.single.location.line, 13);
    });
  });

  group('section 6, code generation', () {
    test('catches generation in the kernel and an unpinned builder', () {
      expect(codesIn('broken_codegen'), {
        'codegen_in_kernel': 3,
        'serialization_in_api': 2,
        'unpinned_builders': 1,
      });
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
