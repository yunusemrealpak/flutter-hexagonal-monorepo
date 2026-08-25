@Tags(['unit'])
library;

import 'package:arch_check/arch_check.dart';
import 'package:test/test.dart';

import 'support/workspace_paths.dart';

void main() {
  group('the workspace rule file', () {
    late RuleSet rules;

    setUp(() {
      rules = RuleSet.fromFile(rulesPath);
    });

    test('declares a policy for every package type', () {
      // Enforced at load time rather than at check time. A type with no policy
      // would be checked against nothing and pass everything, which is the one
      // failure mode of a data-driven checker nobody notices.
      for (final type in PackageType.values) {
        expect(rules.policyFor(type), isNotNull, reason: type.id);
      }
    });

    test('encodes the three edges people get wrong', () {
      expect(
        rules.policyFor(PackageType.featureApplication).allow,
        isNot(contains('platform')),
      );
      expect(
        rules.policyFor(PackageType.featureInfrastructure).allow,
        isNot(contains('foreign_api')),
      );
      expect(
        rules.policyFor(PackageType.platform).allow,
        isNot(contains('platform')),
      );
    });

    test('lets nothing at all into the innermost ring', () {
      final kernel = rules.policyFor(PackageType.coreKernel);
      expect(kernel.allow, isEmpty);
      expect(kernel.allowSdks, isEmpty);
      expect(kernel.allowThirdParty, isFalse);
    });

    test('carries a remedy for every code it can emit', () {
      final codes = {
        'unknown_package_type',
        'forbidden_dependency',
        'dev_dependency_in_lib',
        'missing_barrel',
        'stray_lib_file',
        'deep_import',
        'barrel_leak',
        'name_mismatch',
        'unregistered_package',
        'dependency_cycle',
        'implementation_in_api',
        for (final rule in rules.forbiddenImports) rule.code,
        for (final rule in rules.forbiddenApis.rules) rule.code,
        rules.codegen.noCodegenCode,
        rules.codegen.pinnedBuildersCode,
        for (final banned in rules.codegen.bannedBuilders) banned.code,
      };
      for (final code in codes) {
        expect(
          rules.messages,
          contains(code),
          reason: 'rules.yaml has no remedy for "$code"',
        );
      }
    });

    test('substitutes into a remedy', () {
      expect(
        rules.remedyFor(
          'forbidden_dependency.foreign_feature',
          vars: {'foreign_api': 'shipments_api'},
        ),
        contains('shipments_api'),
      );
    });

    test('says so loudly when a code has no remedy', () {
      expect(rules.remedyFor('no_such_code'), contains('No remedy recorded'));
    });
  });

  group('parsing', () {
    test('rejects a rule file that forgets a package type', () {
      // A type with no policy would be checked against nothing and pass
      // everything, so the file is refused rather than half-applied.
      const source = '''
version: 1
discovery: {roots: [packages], skip_directories: [test]}
feature_root: packages/features
package_types:
  - {type: feature_api, path_prefix: "packages/features/", name_suffix: _api}
dependencies:
  feature_api: {allow: [], allow_sdks: [], allow_third_party: true}
structure:
  deep_import: {scan: [lib]}
  barrel: {}
  implementation_in_api: {in_types: [feature_api]}
forbidden_imports: []
forbidden_apis: {scan: [lib], except_types: [], rules: []}
codegen:
  generated_file_suffixes: [.g.dart]
  no_codegen_in: {types: [core_kernel], code: codegen_in_kernel}
  banned_builders: []
  pinned_builders: {code: unpinned_builders}
messages: {}
''';
      expect(
        () => RuleSet.parse(source),
        throwsA(
          isA<RuleSetException>().having(
            (error) => error.message,
            'message',
            contains('core_kernel'),
          ),
        ),
      );
    });

    test('rejects a rule file written for another version', () {
      expect(
        () => RuleSet.parse('version: 2\n'),
        throwsA(
          isA<RuleSetException>().having(
            (error) => error.message,
            'message',
            contains('version 2'),
          ),
        ),
      );
    });

    test('rejects a file that is not a map', () {
      expect(
        () => RuleSet.parse('- one\n- two\n'),
        throwsA(isA<RuleSetException>()),
      );
    });

    test('rejects an unknown package type', () {
      expect(
        () => RuleSet.parse('''
version: 1
discovery: {roots: [packages], skip_directories: [test]}
feature_root: packages/features
package_types:
  - {type: not_a_type, path: packages/x}
dependencies: {}
structure:
  deep_import: {scan: [lib]}
  barrel: {}
  implementation_in_api: {in_types: []}
forbidden_imports: []
forbidden_apis: {scan: [lib], except_types: [], rules: []}
codegen:
  generated_file_suffixes: [.g.dart]
  no_codegen_in: {types: [core_kernel], code: codegen_in_kernel}
  banned_builders: []
  pinned_builders: {code: unpinned_builders}
messages: {}
'''),
        throwsA(
          isA<RuleSetException>().having(
            (error) => error.message,
            'message',
            contains('not_a_type'),
          ),
        ),
      );
    });
  });
}
