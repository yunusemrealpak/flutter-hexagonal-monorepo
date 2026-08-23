/// Reads the current time.
///
/// This port exists so that no line of product code calls `DateTime.now()`.
/// A use case that reads the system clock is a use case whose tests depend on
/// when they run: a token that expires in five minutes passes today and fails
/// on the day the test machine is slow. With the clock injected, "five minutes
/// later" is something a test states rather than waits for.
///
/// Implementations return UTC. Converting to a local zone is a presentation
/// concern and belongs where the value is rendered, not where it is read.
abstract interface class Clock {
  /// The current instant, in UTC.
  DateTime now();
}
