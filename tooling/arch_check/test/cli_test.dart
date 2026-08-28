@Tags(['unit'])
library;

import 'dart:convert';

import 'package:arch_check/arch_check.dart';
import 'package:test/test.dart';

import 'support/workspace_paths.dart';

void main() {
  late StringBuffer out;
  late StringBuffer err;

  setUp(() {
    out = StringBuffer();
    err = StringBuffer();
  });

  List<String> arguments(String fixtureName, [List<String> extra = const []]) =>
      ['--root=${fixture(fixtureName)}', '--rules=$rulesPath', ...extra];

  group('exit codes', () {
    test('a clean workspace exits 0', () {
      final code = runCli(arguments('clean'), out: out, err: err);
      expect(code, ExitCodes.clean);
      expect(out.toString(), contains('clean — 10 packages'));
    });

    test('violations exit 1', () {
      final code = runCli(arguments('broken_structure'), out: out, err: err);
      expect(code, ExitCodes.violations);
      expect(out.toString(), contains('name_mismatch'));
    });

    test('an unreadable rule file exits 64, not 1', () {
      // Distinct on purpose. A checker that exits 1 both for "the
      // architecture is broken" and for "I could not read my own rules"
      // teaches CI to treat the second as the first.
      final code = runCli(
        [
          '--root=${fixture('clean')}',
          '--rules=${fixture('clean')}/no_such_rules.yaml',
        ],
        out: out,
        err: err,
      );
      expect(code, ExitCodes.misconfigured);
      expect(err.toString(), contains('not found'));
    });

    test('a missing root exits 64', () {
      final code = runCli(
        [
          '--root=${fixture('no_such_fixture')}',
          '--rules=$rulesPath',
        ],
        out: out,
        err: err,
      );
      expect(code, ExitCodes.misconfigured);
      expect(err.toString(), contains('no such directory'));
    });

    test('an unknown flag exits 64 and prints the usage', () {
      final code = runCli(['--nope'], out: out, err: err);
      expect(code, ExitCodes.misconfigured);
      expect(err.toString(), contains('Usage:'));
    });
  });

  group('--help', () {
    test('prints the usage and exits 0', () {
      final code = runCli(['--help'], out: out, err: err);
      expect(code, ExitCodes.clean);
      expect(out.toString(), contains('dependency constitution'));
      expect(out.toString(), contains('--format'));
    });
  });

  group('--format=json', () {
    test('carries the same four fields as the text report', () {
      runCli(
        arguments('broken_structure', ['--format=json']),
        out: out,
        err: err,
      );
      final decoded = jsonDecode(out.toString()) as Map<String, Object?>;
      final violations = decoded['violations']! as List<Object?>;
      final first = violations.first! as Map<String, Object?>;

      expect(first.keys, containsAll(['code', 'location', 'what', 'remedy']));
      expect(first['code'], 'missing_barrel');
      expect(
        (first['location']! as Map<String, Object?>)['package'],
        'apps/app_broken',
      );

      final summary = decoded['summary']! as Map<String, Object?>;
      expect(summary['clean'], isFalse);
      expect(summary['violationCount'], 13);
      expect(summary['packagesChecked'], 4);
    });

    test('a clean run is still valid JSON', () {
      runCli(arguments('clean', ['--format=json']), out: out, err: err);
      final decoded = jsonDecode(out.toString()) as Map<String, Object?>;
      expect(decoded['violations'], isEmpty);
      expect((decoded['summary']! as Map<String, Object?>)['clean'], isTrue);
    });
  });

  group('the text report', () {
    test('gives every violation a code, a location, a what and a remedy', () {
      runCli(arguments('broken_structure'), out: out, err: err);
      final lines = out.toString().split('\n');
      // The app row's shape of S1: an app has no barrel to be missing, so the
      // "what" names the entry point it has none of instead.
      expect(lines.first, 'missing_barrel  apps/app_broken');
      expect(lines[1].trim(), startsWith('there is no entry point under lib/'));
      expect(lines[2].trim(), startsWith('Add lib/<package_name>.dart'));
    });

    test('is stable across runs, so the report can be diffed', () {
      final second = StringBuffer();
      runCli(arguments('broken_structure'), out: out, err: err);
      runCli(arguments('broken_structure'), out: second, err: err);
      expect(second.toString(), out.toString());
    });
  });
}
