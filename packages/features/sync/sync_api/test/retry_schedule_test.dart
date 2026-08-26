@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:sync_api/sync_api.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  group('RetrySchedule.of', () {
    test('accepts a schedule that can work', () {
      final schedule = unwrap(
        RetrySchedule.of(
          baseDelay: const Duration(seconds: 2),
          maxDelay: const Duration(minutes: 1),
          maxAttempts: 4,
        ),
      );

      expect(schedule.baseDelay, const Duration(seconds: 2));
      expect(schedule.maxAttempts, 4);
    });

    test('refuses a zero base delay', () {
      // Every retry would be immediate, and a failing server would be
      // hammered by the clients it just failed.
      expect(
        RetrySchedule.of(
          baseDelay: Duration.zero,
          maxDelay: const Duration(minutes: 1),
          maxAttempts: 4,
        ),
        const Failed<RetrySchedule, SyncFailure>(
          MalformedEntry(field: 'baseDelay', reason: 'must be positive'),
        ),
      );
    });

    test('refuses a cap shorter than the first wait', () {
      expect(
        RetrySchedule.of(
          baseDelay: const Duration(minutes: 1),
          maxDelay: const Duration(seconds: 1),
          maxAttempts: 4,
        ).isFailure,
        isTrue,
      );
    });

    test('refuses a schedule that allows no attempts', () {
      expect(
        RetrySchedule.of(
          baseDelay: const Duration(seconds: 1),
          maxDelay: const Duration(minutes: 1),
          maxAttempts: 0,
        ).isFailure,
        isTrue,
      );
    });
  });

  group('delayAfter', () {
    const schedule = RetrySchedule.standard;

    test('doubles with each failure, at full jitter', () {
      // jitter: 1 is clamped just below 1.0, so the delays come out a
      // microsecond short of the raw backoff. Asserting on the whole shape at
      // once is what catches an off-by-one in the exponent.
      final delays = [1, 2, 3, 4]
          .map((attempts) => schedule.delayAfter(attempts, jitter: 1).inSeconds)
          .toList();

      expect(delays, [0, 1, 3, 7]);
    });

    test('never exceeds the cap, however many failures there have been', () {
      expect(
        schedule.delayAfter(30, jitter: 1),
        lessThanOrEqualTo(const Duration(minutes: 5)),
      );
    });

    test('scales the backoff by the jitter it is given', () {
      // Full jitter: the delay is a draw from [0, backoff], not backoff plus a
      // wobble. That is what spreads a depot's worth of devices that all lost
      // wifi at the same second.
      expect(
        schedule.delayAfter(3, jitter: 0.5),
        const Duration(seconds: 2),
      );
    });

    test('waits nothing at all when the draw is zero', () {
      expect(schedule.delayAfter(5, jitter: 0), Duration.zero);
    });

    test('treats a zeroth attempt as the first', () {
      expect(
        schedule.delayAfter(0, jitter: 1),
        schedule.delayAfter(1, jitter: 1),
      );
    });

    test('clamps a jitter outside [0, 1) instead of producing nonsense', () {
      // A RandomSource is a port, and a fake is entitled to be wrong. A
      // negative delay would be applied as a due time in the past and would
      // turn one bad fake into a hot loop.
      expect(schedule.delayAfter(4, jitter: -1), Duration.zero);
      expect(
        schedule.delayAfter(4, jitter: 5),
        lessThanOrEqualTo(const Duration(seconds: 8)),
      );
      expect(schedule.delayAfter(4, jitter: double.nan), Duration.zero);
    });
  });

  group('allowsAnotherAttempt', () {
    test('stops at the limit', () {
      const schedule = RetrySchedule.standard;

      expect(schedule.allowsAnotherAttempt(7), isTrue);
      expect(schedule.allowsAnotherAttempt(8), isFalse);
      expect(schedule.allowsAnotherAttempt(9), isFalse);
    });
  });
}
