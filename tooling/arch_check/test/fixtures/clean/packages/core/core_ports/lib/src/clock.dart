/// The port that exists so that no line of product code reads the clock
/// itself. Documented with the very call it forbids, which is the case a
/// text-scanning checker gets wrong: `DateTime.now()`.
abstract interface class Clock {
  /// The current instant, in UTC.
  DateTime now();
}
