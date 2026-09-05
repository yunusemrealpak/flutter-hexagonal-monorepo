import 'package:core_kernel/core_kernel.dart';

import '../failures/sync_failure.dart';

/// How long to wait before attempting a queued entry again.
///
/// Exponential backoff with full jitter, capped, and with a hard limit on how
/// many attempts a single entry gets before it stops being retried at all.
///
/// The whole thing is a pure function of `(attempt, jitter)`. That is the
/// point of putting it here rather than in the use case that drains: the
/// randomness arrives as a number the caller obtained from the `RandomSource`
/// port, so a test can state "the jitter was 0.5" instead of running the
/// schedule a thousand times and asserting on a distribution.
///
/// **Why jitter at all.** Without it, every device that lost connectivity at
/// the same moment — which is what happens when a depot's wifi drops — comes
/// back at the same moment, and the server that was fine a second ago is
/// handed the entire fleet's backlog at once. Jitter spreads the return.
///
/// Hand-written rather than generated: it validates its own inputs and it
/// carries a rule, which is the line this workspace draws around `freezed`.
final class RetrySchedule {
  const RetrySchedule._({
    required this.baseDelay,
    required this.maxDelay,
    required this.maxAttempts,
  });

  /// The schedule the product ships with.
  ///
  /// One second doubling to five minutes, giving up after eight attempts —
  /// which is a little over twenty minutes of trying, or a whole shift if the
  /// device is offline for one, because an offline device never gets as far as
  /// an attempt.
  static const RetrySchedule standard = RetrySchedule._(
    baseDelay: Duration(seconds: 1),
    maxDelay: Duration(minutes: 5),
    maxAttempts: 8,
  );

  /// Builds a schedule, refusing one that cannot work.
  ///
  /// A zero base delay would make every retry immediate and turn a failing
  /// server into a denial-of-service attack mounted by its own clients; a
  /// [maxDelay] below [baseDelay] would make the cap shrink the first wait
  /// rather than bound the last.
  static Result<RetrySchedule, SyncFailure> of({
    required Duration baseDelay,
    required Duration maxDelay,
    required int maxAttempts,
  }) {
    if (baseDelay <= Duration.zero) {
      return const Failed(
        MalformedEntry(field: 'baseDelay', reason: 'must be positive'),
      );
    }
    if (maxDelay < baseDelay) {
      return const Failed(
        MalformedEntry(
          field: 'maxDelay',
          reason: 'must not be shorter than baseDelay',
        ),
      );
    }
    if (maxAttempts < 1) {
      return const Failed(
        MalformedEntry(field: 'maxAttempts', reason: 'must be at least 1'),
      );
    }
    return Success(
      RetrySchedule._(
        baseDelay: baseDelay,
        maxDelay: maxDelay,
        maxAttempts: maxAttempts,
      ),
    );
  }

  /// The wait after the first failure, before jitter and before the cap.
  final Duration baseDelay;

  /// The longest this schedule will ever wait.
  final Duration maxDelay;

  /// How many attempts an entry gets before it is given up on.
  final int maxAttempts;

  /// Whether an entry that has been tried [attempts] times gets another go.
  bool allowsAnotherAttempt(int attempts) => attempts < maxAttempts;

  /// How long to wait after [attempts] failures, given a [jitter] in `[0, 1)`.
  ///
  /// Full jitter: the delay is a uniform draw from `[0, backoff]` rather than
  /// `backoff` plus a small wobble. It spreads a synchronised fleet far better
  /// for the same amount of randomness, and the cost — an occasional retry
  /// that comes back almost immediately — is paid by one device rather than by
  /// the server.
  ///
  /// [attempts] below 1 is treated as 1: "wait before the zeroth attempt" is
  /// not a question the drain asks, and answering it with a negative exponent
  /// would produce a delay shorter than [baseDelay].
  Duration delayAfter(int attempts, {required double jitter}) {
    final exponent = attempts < 1 ? 0 : attempts - 1;
    // Shifting rather than pow(): the exponent is small and bounded by
    // maxAttempts, and an int shift cannot drift the way a double can.
    final capped = exponent > 30 ? 1 << 30 : 1 << exponent;
    final backoffMicros = baseDelay.inMicroseconds * capped;
    final bounded = backoffMicros > maxDelay.inMicroseconds
        ? maxDelay.inMicroseconds
        : backoffMicros;

    final clamped = jitter.isNaN || jitter < 0
        ? 0.0
        : (jitter >= 1 ? 0.999999 : jitter);
    return Duration(microseconds: (bounded * clamped).round());
  }

  @override
  String toString() =>
      'RetrySchedule(${baseDelay.inMilliseconds}ms..'
      '${maxDelay.inSeconds}s, max $maxAttempts)';
}
