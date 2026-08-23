@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:test/test.dart';

/// A failure hierarchy of the shape every `_api` package declares, used here to
/// prove that a `sealed` subtype of [Failure] survives a round trip through
/// [Result] and stays exhaustively matchable.
sealed class _ProbeFailure extends Failure {
  const _ProbeFailure();
}

final class _NotFound extends _ProbeFailure {
  const _NotFound();
}

final class _Rejected extends _ProbeFailure {
  const _Rejected(this.reason);

  final String reason;
}

void main() {
  group('Result.fold', () {
    test('runs the success branch and ignores the failure branch', () {
      const result = Success<int, String>(7);

      final folded = result.fold(
        (value) => 'ok:$value',
        (failure) => 'err:$failure',
      );

      expect(folded, 'ok:7');
    });

    test('runs the failure branch and ignores the success branch', () {
      const result = Failed<int, String>('boom');

      final folded = result.fold(
        (value) => 'ok:$value',
        (failure) => 'err:$failure',
      );

      expect(folded, 'err:boom');
    });
  });

  group('Result.map', () {
    test('transforms a success value', () {
      const result = Success<int, String>(2);

      expect(result.map((value) => value * 3), const Success<int, String>(6));
    });

    test('leaves a failure untouched and does not run the transform', () {
      var transformCalls = 0;
      const result = Failed<int, String>('boom');

      final mapped = result.map((value) {
        transformCalls++;
        return value * 3;
      });

      expect(mapped, const Failed<int, String>('boom'));
      expect(transformCalls, 0);
    });
  });

  group('Result.flatMap', () {
    test('chains a second operation without nesting the results', () {
      const result = Success<int, String>(4);

      final chained = result.flatMap(
        (value) => Success<String, String>('v$value'),
      );

      expect(chained, const Success<String, String>('v4'));
    });

    test('short-circuits on the first failure', () {
      var transformCalls = 0;
      const result = Failed<int, String>('first');

      final chained = result.flatMap((value) {
        transformCalls++;
        return const Success<String, String>('unreachable');
      });

      expect(chained, const Failed<String, String>('first'));
      expect(transformCalls, 0);
    });

    test('propagates a failure produced by the chained operation', () {
      const result = Success<int, String>(4);

      final chained = result.flatMap(
        (value) => const Failed<String, String>('second'),
      );

      expect(chained, const Failed<String, String>('second'));
    });
  });

  group('Result.mapFailure', () {
    test(
      'translates a failure, which is what an adapter does at its boundary',
      () {
        const transportFailure = Failed<int, String>('SocketException');

        final translated = transportFailure.mapFailure<_ProbeFailure>(
          (raw) => const _NotFound(),
        );

        expect(translated, const Failed<int, _ProbeFailure>(_NotFound()));
      },
    );

    test('leaves a success untouched and does not run the transform', () {
      var transformCalls = 0;
      const result = Success<int, String>(1);

      final translated = result.mapFailure<_ProbeFailure>((raw) {
        transformCalls++;
        return const _NotFound();
      });

      expect(translated, const Success<int, _ProbeFailure>(1));
      expect(transformCalls, 0);
    });
  });

  group('exhaustive matching', () {
    test('a sealed failure stays matchable after a round trip', () {
      const Result<int, _ProbeFailure> result = Failed(_Rejected('too heavy'));

      final described = switch (result) {
        Success(:final value) => 'ok:$value',
        Failed(failure: _NotFound()) => 'not-found',
        Failed(failure: _Rejected(:final reason)) => 'rejected:$reason',
      };

      expect(described, 'rejected:too heavy');
    });
  });

  group('equality and predicates', () {
    test('two successes carrying equal values are equal', () {
      expect(const Success<int, String>(1), const Success<int, String>(1));
      expect(
        const Success<int, String>(1).hashCode,
        const Success<int, String>(1).hashCode,
      );
    });

    test('a success and a failure are never equal', () {
      expect(
        const Success<int, String>(1),
        isNot(const Failed<int, String>('1')),
      );
    });

    test('isSuccess and isFailure report the branch', () {
      expect(const Success<int, String>(1).isSuccess, isTrue);
      expect(const Success<int, String>(1).isFailure, isFalse);
      expect(const Failed<int, String>('x').isFailure, isTrue);
      expect(const Failed<int, String>('x').isSuccess, isFalse);
    });

    test('prints usefully', () {
      expect(const Success<int, String>(1).toString(), 'Success(1)');
      expect(const Failed<int, String>('x').toString(), 'Failed(x)');
    });
  });
}
