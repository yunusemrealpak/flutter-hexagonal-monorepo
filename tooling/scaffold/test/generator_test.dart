@Tags(['unit'])
library;

import 'package:scaffold/scaffold.dart';
import 'package:test/test.dart';

import 'support/temp_workspace.dart';

void main() {
  late TempWorkspace workspace;

  setUp(() => workspace = TempWorkspace.create());
  tearDown(() => workspace.dispose());

  FeaturePlan planFor({
    FeatureSplit split = FeatureSplit.full,
    bool withTesting = false,
  }) => FeaturePlan.of(
    feature: 'billing',
    split: split,
    existingPackages: WorkspaceRegistration(
      workspace.root,
    ).registeredPackageNames(),
    withTesting: withTesting,
  );

  ScaffoldResult generate({
    bool dryRun = false,
    bool force = false,
    bool codegen = false,
    FeatureSplit split = FeatureSplit.full,
    bool withTesting = false,
  }) => Generator(
    rootPath: workspace.root,
    dryRun: dryRun,
    force: force,
    codegen: codegen,
  ).generate(planFor(split: split, withTesting: withTesting));

  group('what a generated package contains', () {
    test('a barrel, seed sources, a test, a README and a dart_test.yaml', () {
      generate();
      const api = 'packages/features/billing/billing_api';
      expect(workspace.exists('$api/pubspec.yaml'), isTrue);
      expect(workspace.exists('$api/README.md'), isTrue);
      expect(workspace.exists('$api/dart_test.yaml'), isTrue);
      expect(workspace.exists('$api/lib/billing_api.dart'), isTrue);
      expect(
        workspace.exists('$api/lib/src/failures/billing_failure.dart'),
        isTrue,
      );
      expect(workspace.exists('$api/test/billing_api_test.dart'), isTrue);
    });

    test('the barrel exports every seed source and nothing else', () {
      generate();
      final barrel = workspace.read(
        'packages/features/billing/billing_api/lib/billing_api.dart',
      );
      expect(barrel, contains("export 'src/failures/billing_failure.dart';"));
      expect(
        barrel,
        contains("export 'src/ports/driven/billing_repository.dart';"),
      );
      expect(barrel.split('export ').length - 1, 2);
    });

    // The layout, not just the files. A contract package is where the
    // hexagon's two kinds of port are declared, and section 7 of CLAUDE.md
    // says the filesystem shows that split. A seed that wrote its port next
    // to its failure would teach the flat layout to every feature scaffolded
    // after it, which is how a convention that lives only in a document dies.
    test('the _api seed is laid out in folders by kind', () {
      generate();
      const api = 'packages/features/billing/billing_api';
      expect(
        workspace.exists('$api/lib/src/ports/driven/billing_repository.dart'),
        isTrue,
      );
      expect(
        workspace.exists('$api/lib/src/failures/billing_failure.dart'),
        isTrue,
      );
      // A port reaches its failure across two folders, so the seed has to get
      // the relative import right or the package does not compile.
      final port = workspace.read(
        '$api/lib/src/ports/driven/billing_repository.dart',
      );
      expect(port, contains("import '../../failures/billing_failure.dart';"));
    });

    test('nothing but the barrel sits directly under lib/', () {
      generate();
      final strays = workspace
          .files()
          .where((path) => RegExp(r'/lib/[^/]+\.dart$').hasMatch(path))
          .where((path) => !path.endsWith('/lib/stub.dart'))
          .toList();
      for (final path in strays) {
        final package = path.split('/lib/').first.split('/').last;
        expect(path, endsWith('/lib/$package.dart'));
      }
    });

    test('no build.yaml by default, because nothing is generated yet', () {
      generate();
      expect(
        workspace.files().where((path) => path.endsWith('build.yaml')),
        isEmpty,
      );
    });

    test('--codegen wires the builder each role would use', () {
      generate(codegen: true);
      final api = workspace.read(
        'packages/features/billing/billing_api/build.yaml',
      );
      expect(api, contains('freezed:'));
      expect(api, contains('generate_for:'));
      expect(
        workspace.read(
          'packages/features/billing/billing_infrastructure/build.yaml',
        ),
        contains('json_serializable:'),
      );
      // The one role that generates nothing gets no build.yaml even here.
      expect(
        workspace.exists(
          'packages/features/billing/billing_application/build.yaml',
        ),
        isFalse,
      );
    });
  });

  group('the root pubspec', () {
    test('gains one sorted entry per package', () {
      final result = generate(withTesting: true);
      expect(result.registered, [
        'packages/features/billing/billing_api',
        'packages/features/billing/billing_application',
        'packages/features/billing/billing_infrastructure',
        'packages/features/billing/billing_presentation',
        'packages/features/billing/billing_testing',
      ]);
      expect(
        WorkspaceRegistration(workspace.root).read(),
        containsAll(result.registered),
      );
    });

    test('keeps the list sorted, not appended to', () {
      generate();
      final entries = WorkspaceRegistration(workspace.root).read();
      expect(entries, orderedEquals([...entries]..sort()));
    });

    test('keeps its comments', () {
      // The reasoning behind the melos scripts lives in comments in the real
      // root pubspec, which is why the edit splices lines instead of round
      // tripping through a YAML writer.
      generate();
      expect(
        workspace.read('pubspec.yaml'),
        contains('# A comment inside the root pubspec'),
      );
    });
  });

  group('re-running the scaffolder', () {
    test('leaves existing files alone', () {
      generate();
      const barrel =
          'packages/features/billing/billing_api/lib/billing_api.dart';
      final edited = '${workspace.read(barrel)}\n// edited by hand\n';
      workspace.write(barrel, edited);

      final second = generate();

      expect(second.created, isEmpty);
      expect(second.skipped, contains(barrel));
      expect(workspace.read(barrel), edited);
    });

    test('adds only the package that was missing', () {
      // The reason someone re-runs it: the _testing package they skipped.
      generate();
      final second = generate(withTesting: true);
      expect(
        second.created.map((path) => path.split('/')[3]).toSet(),
        {'billing_testing'},
      );
      expect(second.registered, [
        'packages/features/billing/billing_testing',
      ]);
    });

    test('--force overwrites', () {
      generate();
      const barrel =
          'packages/features/billing/billing_api/lib/billing_api.dart';
      workspace.write(barrel, '// gone\n');

      generate(force: true);

      expect(workspace.read(barrel), contains("export 'src/"));
    });
  });

  group('--dry-run', () {
    test('writes nothing at all, including the root pubspec', () {
      final before = workspace.read('pubspec.yaml');
      final result = generate(dryRun: true);

      expect(result.created, isNotEmpty);
      expect(result.registered, isNotEmpty);
      expect(
        workspace.exists('packages/features/billing/billing_api/pubspec.yaml'),
        isFalse,
      );
      expect(workspace.read('pubspec.yaml'), before);
    });
  });
}
