import 'package:core_ports/core_ports.dart';

/// A [RandomSource] that returns a scripted sequence and then repeats it.
///
/// Retry backoff jitter is the reason this exists. A test that asserts "the
/// third attempt waits between 4 and 8 seconds" cannot do so against real
/// randomness; against a scripted source, the schedule is an exact value.
final class FakeRandomSource implements RandomSource {
  /// Cycles through [doubles] for [nextDouble], each value in the range
  /// 0.0 (inclusive) to 1.0 (exclusive).
  ///
  /// [nextInt] is derived from the same sequence, so one script drives both.
  FakeRandomSource([List<double> doubles = const [0.5]])
    : assert(
        doubles.isNotEmpty,
        'FakeRandomSource needs at least one value',
      ),
      _values = List<double>.of(doubles);

  final List<double> _values;
  int _cursor = 0;

  double _next() {
    final value = _values[_cursor % _values.length];
    _cursor++;
    return value;
  }

  @override
  double nextDouble() => _next();

  @override
  int nextInt(int max) {
    if (max <= 0) {
      throw ArgumentError.value(max, 'max', 'must be positive');
    }
    return (_next() * max).floor().clamp(0, max - 1);
  }
}
