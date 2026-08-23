import 'package:core_ports/core_ports.dart';

/// A [Clock] whose time only moves when a test moves it.
///
/// This is the single most load-bearing fake in the workspace. Any behaviour
/// that depends on elapsed time — a token refreshing before it expires, a
/// retry backing off, a route recalculating after a deviation — is either
/// tested against this clock or tested by sleeping, and sleeping is how a
/// suite becomes slow and flaky at the same time.
final class FakeClock implements Clock {
  /// Starts at [start], or at a fixed arbitrary instant when none is given.
  ///
  /// The default is deliberately not "now": a test that passes only in 2026 is
  /// a test that will fail one day for no reason anybody remembers.
  FakeClock([DateTime? start])
    : _now = start?.toUtc() ?? DateTime.utc(2026, 1, 1, 9);

  DateTime _now;

  @override
  DateTime now() => _now;

  /// Moves time forward by [duration].
  ///
  /// Rejects a negative duration: a clock that can run backwards makes every
  /// assertion about ordering meaningless, and a test that wants an earlier
  /// instant should construct one rather than rewind.
  void advance(Duration duration) {
    if (duration.isNegative) {
      throw ArgumentError.value(
        duration,
        'duration',
        'FakeClock cannot run backwards',
      );
    }
    _now = _now.add(duration);
  }

  /// Jumps to [instant], regardless of direction.
  ///
  /// For setting up a scenario, not for use mid-assertion.
  void setTo(DateTime instant) => _now = instant.toUtc();
}
