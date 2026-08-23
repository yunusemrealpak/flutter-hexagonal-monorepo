@Tags(['unit'])
library;

import 'package:core_testing/core_testing.dart';
import 'package:test/test.dart';

void main() {
  group('FakeClock', () {
    test('does not start at the real now, so tests never age out', () {
      final clock = FakeClock();

      expect(clock.now(), DateTime.utc(2026, 1, 1, 9));
    });

    test('only moves when a test moves it', () {
      final clock = FakeClock();
      final first = clock.now();

      expect(clock.now(), first);

      clock.advance(const Duration(minutes: 5));

      expect(clock.now(), first.add(const Duration(minutes: 5)));
    });

    test('refuses to run backwards', () {
      final clock = FakeClock();

      expect(
        () => clock.advance(const Duration(seconds: -1)),
        throwsArgumentError,
      );
    });

    test('reports UTC even when set from a local instant', () {
      final clock = FakeClock()..setTo(DateTime(2026, 6, 1, 12));

      expect(clock.now().isUtc, isTrue);
    });
  });

  group('FakeIdGenerator', () {
    test('counts, so identifiers are distinct and predictable', () {
      final ids = FakeIdGenerator();

      expect([ids.newId(), ids.newId()], ['id-1', 'id-2']);
    });

    test('takes a prefix so two generators in one test stay readable', () {
      final ids = FakeIdGenerator('key');

      expect(ids.newId(), 'key-1');
    });

    test('hands out a script in order', () {
      final ids = FakeIdGenerator.scripted(['a', 'b']);

      expect([ids.newId(), ids.newId()], ['a', 'b']);
    });

    test('throws instead of inventing a value past the end of the script', () {
      final ids = FakeIdGenerator.scripted(['only'])..newId();

      expect(ids.newId, throwsStateError);
    });

    test('counts issues, which is how idempotency gets asserted', () {
      final ids = FakeIdGenerator()
        ..newId()
        ..newId();

      expect(ids.issuedCount, 2);
    });
  });

  group('FakeRandomSource', () {
    test('returns the scripted sequence and then repeats it', () {
      final random = FakeRandomSource([0.1, 0.9]);

      expect(
        [random.nextDouble(), random.nextDouble(), random.nextDouble()],
        [0.1, 0.9, 0.1],
      );
    });

    test('derives nextInt from the same sequence', () {
      final random = FakeRandomSource([0.0, 0.5, 0.999]);

      expect(
        [random.nextInt(10), random.nextInt(10), random.nextInt(10)],
        [
          0,
          5,
          9,
        ],
      );
    });

    test('rejects a non-positive bound', () {
      final random = FakeRandomSource();

      expect(() => random.nextInt(0), throwsArgumentError);
    });
  });
}
