@Tags(['unit'])
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_runner/test_runner.dart';

import 'support/harness.dart';

void main() {
  late Directory workspace;
  late List<TestPackage> packages;
  late PackageHasher hasher;

  setUp(() {
    workspace = copyFixture('mini');
    packages = const WorkspaceReader().read(workspace.path);
    hasher = PackageHasher(rootPath: workspace.path, packages: packages);
  });

  tearDown(() => workspace.deleteSync(recursive: true));

  TestPackage named(String name) =>
      packages.firstWhere((package) => package.name == name);

  File inside(String package, String relative) => File(
    p.join(named(package).absolutePath, relative),
  );

  group('the fingerprint', () {
    test('is stable when nothing moved', () {
      expect(hasher.hash(named('alpha_api')), hasher.hash(named('alpha_api')));
    });

    test('moves when the package moves', () {
      final before = hasher.hash(named('alpha_api'));
      inside('alpha_api', 'lib/api.dart').writeAsStringSync('const api = 2;');

      final after = PackageHasher(
        rootPath: workspace.path,
        packages: packages,
      ).hash(named('alpha_api'));

      expect(after, isNot(before));
    });

    test('moves when a package it depends on moves', () {
      // The case the cache exists to get right. A hash of the package alone
      // would skip alpha_application's suite after a change to alpha_api.
      final before = hasher.hash(named('alpha_application'));
      inside('alpha_api', 'lib/api.dart').writeAsStringSync('const api = 3;');

      final after = PackageHasher(
        rootPath: workspace.path,
        packages: packages,
      ).hash(named('alpha_application'));

      expect(after, isNot(before));
    });

    test('moves when the resolution moves', () {
      final before = hasher.hash(named('core_kernel'));
      File(
        p.join(workspace.path, 'pubspec.lock'),
      ).writeAsStringSync('packages: {a: 1}\n');

      final after = PackageHasher(
        rootPath: workspace.path,
        packages: packages,
      ).hash(named('core_kernel'));

      expect(after, isNot(before));
    });

    test('covers the test directory as well as lib', () {
      final before = hasher.hash(named('core_kernel'));
      inside(
        'core_kernel',
        'test/kernel_test.dart',
      ).writeAsStringSync('void main() { /* new */ }');

      final after = PackageHasher(
        rootPath: workspace.path,
        packages: packages,
      ).hash(named('core_kernel'));

      expect(after, isNot(before));
    });
  });

  group('the cache', () {
    test('round-trips through a file', () {
      final path = TestHashCache.pathFor(workspace.path);
      TestHashCache.load(path)
        ..record('alpha_api', 'abc')
        ..save();

      expect(TestHashCache.load(path).isFresh('alpha_api', 'abc'), isTrue);
      expect(TestHashCache.load(path).isFresh('alpha_api', 'xyz'), isFalse);
    });

    test('a corrupt file re-runs everything rather than failing', () {
      // The worst a bad cache may cost is time. A runner that refused to start
      // because of one would be worse than no cache at all.
      final path = TestHashCache.pathFor(workspace.path);
      File(path)
        ..createSync(recursive: true)
        ..writeAsStringSync('{not json');

      expect(TestHashCache.load(path).isFresh('alpha_api', 'abc'), isFalse);
    });

    test('forgetting a package un-skips its next run', () {
      final cache = TestHashCache.load(TestHashCache.pathFor(workspace.path))
        ..record('alpha_api', 'abc')
        ..forget('alpha_api');

      expect(cache.isFresh('alpha_api', 'abc'), isFalse);
    });
  });

  group('bucketing', () {
    final timings = Timings(
      File(p.join(Directory.systemTemp.path, 'unused.json')),
      {'slow': 100, 'medium': 40, 'quick': 5, 'quicker': 4},
    );

    List<TestPackage> of(List<String> names) => [
      for (final name in names)
        TestPackage(
          name: name,
          relativePath: 'packages/$name',
          absolutePath: '/tmp/$name',
          dependencies: const [],
          devDependencies: const [],
          usesFlutter: false,
          hasTests: true,
        ),
    ];

    test('the heaviest package lands alone', () {
      // Splitting by count would put the slow suite next to three quick ones
      // and leave the other machine idle.
      final all = of(['slow', 'medium', 'quick', 'quicker']);

      final first = bucketOf(all, timings, index: 0, total: 2);
      final second = bucketOf(all, timings, index: 1, total: 2);

      expect(first.map((p) => p.name), ['slow']);
      expect(second.map((p) => p.name), ['medium', 'quick', 'quicker']);
    });

    test('every package lands in exactly one bucket', () {
      final all = of(['slow', 'medium', 'quick', 'quicker']);
      final seen = [
        for (var i = 0; i < 3; i++)
          ...bucketOf(all, timings, index: i, total: 3).map((p) => p.name),
      ];

      expect(seen..sort(), ['medium', 'quick', 'quicker', 'slow']);
    });

    test('the same input always splits the same way', () {
      // A bucketing that shuffled would make a flaky failure impossible to
      // reproduce on the machine that saw it.
      final all = of(['slow', 'medium', 'quick', 'quicker']);

      expect(
        bucketOf(all, timings, index: 0, total: 2).map((p) => p.name),
        bucketOf(all, timings, index: 0, total: 2).map((p) => p.name),
      );
    });

    test('one bucket is every package, untouched', () {
      final all = of(['slow', 'quick']);

      expect(bucketOf(all, timings, index: 0, total: 1), all);
    });
  });
}
