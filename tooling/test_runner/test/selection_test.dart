@Tags(['unit'])
library;

import 'package:test/test.dart';
import 'package:test_runner/test_runner.dart';

import 'support/harness.dart';

void main() {
  final packages = const WorkspaceReader().read(fixture('mini'));
  final affected = AffectedPackages(packages);

  group('the workspace reader', () {
    test('reads the registered packages, and only those', () {
      expect(packages.map((package) => package.name), [
        'core_docs',
        'core_kernel',
        'alpha_api',
        'alpha_application',
        'widget_kit',
      ]);
    });

    test('a third-party dependency is not an internal edge', () {
      final api = packages.firstWhere((package) => package.name == 'alpha_api');

      expect(api.dependencies, ['core_kernel']);
    });

    test('dev dependencies are kept apart from runtime ones', () {
      final application = packages.firstWhere(
        (package) => package.name == 'alpha_application',
      );

      expect(application.dependencies, ['alpha_api']);
      expect(application.devDependencies, ['core_kernel']);
    });

    test('the runner is read from the pubspec, not from the path', () {
      // `widget_kit` binds Flutter through both blocks; `alpha_api` binds
      // neither. Guessing from the path would put a platform package and an
      // _api package in the same bucket — they live at the same depth.
      final kit = packages.firstWhere((p) => p.name == 'widget_kit');
      final api = packages.firstWhere((p) => p.name == 'alpha_api');

      expect(kit.usesFlutter, isTrue);
      expect(api.usesFlutter, isFalse);
    });

    test('a package with no test directory is known and not runnable', () {
      final docs = packages.firstWhere((p) => p.name == 'core_docs');

      expect(docs.hasTests, isFalse);
    });
  });

  group('affected packages', () {
    test('a file maps to the package that owns it', () {
      expect(
        affected.directlyChanged([
          'packages/features/alpha/alpha_api/lib/a.dart',
        ]),
        {'alpha_api'},
      );
    });

    test('a change to a contract runs everything that depends on it', () {
      final selected = affected.forChanges([
        'packages/features/alpha/alpha_api/lib/api.dart',
      ]);

      expect(selected.map((package) => package.name), [
        'alpha_api',
        'alpha_application',
        'widget_kit',
      ]);
    });

    test('a dev-dependency edge is walked too', () {
      // alpha_application dev-depends on core_kernel. A change to a contract
      // kit cannot break anybody's build and can certainly break their suite,
      // and a runner that ignored that would go green on a broken fake.
      final selected = affected.forChanges([
        'packages/core/core_kernel/lib/kernel.dart',
      ]);

      expect(
        selected.map((package) => package.name),
        containsAll(['core_kernel', 'alpha_application']),
      );
    });

    test('a package with no tests is walked and not run', () {
      final selected = affected.forChanges([
        'packages/core/core_docs/pubspec.yaml',
      ]);

      expect(selected, isEmpty);
    });

    test('a root file nobody owns runs everything', () {
      // The root pubspec pins every version in the workspace and the lockfile
      // is the resolution itself. Answering "nothing is affected" would be
      // wrong in the most expensive direction.
      expect(affected.touchesEverything(['pubspec.lock']), isTrue);
      expect(
        affected.forChanges(['pubspec.lock']).map((p) => p.name),
        hasLength(4),
      );
    });

    test('a file outside every package selects nothing', () {
      expect(affected.forChanges(['.github/workflows/pr.yml']), isEmpty);
    });
  });

  group('git', () {
    test('the union of four questions is what changed', () async {
      final commands = FakeCommands(
        answers: {
          'git diff --name-only origin/main...HEAD': said('a.dart\n'),
          'git diff --name-only --cached': said('b.dart\n'),
          'git diff --name-only': said('c.dart\n'),
          'git ls-files --others --exclude-standard': said('d.dart\n'),
        },
      );

      final changed = await GitChanges(commands).since(
        'origin/main',
        root: '.',
      );

      expect(changed, {'a.dart', 'b.dart', 'c.dart', 'd.dart'});
    });

    test('a base git cannot resolve gives up rather than guessing', () async {
      // A selective run built on a failed diff silently covers nothing, and a
      // green CI on an unfetched base is the failure nobody notices.
      final commands = FakeCommands(
        answers: {'git diff --name-only nope...HEAD': failed},
      );

      expect(await GitChanges(commands).since('nope', root: '.'), isNull);
    });
  });
}
