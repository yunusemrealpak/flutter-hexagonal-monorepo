/// The severity of a log record.
///
/// Ordered from least to most severe, so an adapter can filter with a simple
/// comparison on [index].
enum LogLevel {
  /// Detail useful while working on the code, and noise everywhere else.
  debug,

  /// A normal event worth recording — a use case completed, a sync drained.
  info,

  /// Something recoverable that a human should eventually look at.
  warning,

  /// Something failed in a way the code could not resolve on its own.
  error,
}
