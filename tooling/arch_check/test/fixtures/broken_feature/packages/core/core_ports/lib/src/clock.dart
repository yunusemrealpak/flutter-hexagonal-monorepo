/// The port that exists so no line of product code reads the clock itself.
abstract interface class Clock {
  /// The current instant, in UTC.
  DateTime now();
}
