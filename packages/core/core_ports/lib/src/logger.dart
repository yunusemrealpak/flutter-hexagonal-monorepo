import 'package:core_ports/src/log_level.dart';

/// Records what the application did, without saying where the record goes.
///
/// This is the port a pure Dart package uses instead of `print` or
/// `debugPrint`. `print` writes to a place only a developer with a console can
/// read, and `debugPrint` would drag the Flutter SDK into `_application`
/// packages that are deliberately pure Dart.
///
/// The interface carries a single method so that a fake or a real adapter has
/// one thing to implement. The four severities developers actually type are
/// supplied by [LoggerLevels] as extension methods, which keeps the
/// convenience out of the contract.
///
/// Logging never fails from the caller's point of view. An adapter that cannot
/// reach its destination drops the record; a use case must not change what it
/// does because a log line did not land.
abstract interface class Logger {
  /// Records [message] at [level].
  ///
  /// [context] carries structured fields for the record — identifiers, counts,
  /// durations. It is not a place for anything a person should not see in a
  /// log aggregator.
  ///
  /// [error] and [stackTrace] are for the caught object at an adapter
  /// boundary, which is the one place in this architecture where an exception
  /// legitimately exists.
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context,
  });
}

/// The severity shorthands, kept off the [Logger] interface so that
/// implementing the port stays a one-method job.
extension LoggerLevels on Logger {
  /// Records [message] at [LogLevel.debug].
  void debug(String message, {Map<String, Object?> context = const {}}) =>
      log(LogLevel.debug, message, context: context);

  /// Records [message] at [LogLevel.info].
  void info(String message, {Map<String, Object?> context = const {}}) =>
      log(LogLevel.info, message, context: context);

  /// Records [message] at [LogLevel.warning].
  void warning(String message, {Map<String, Object?> context = const {}}) =>
      log(LogLevel.warning, message, context: context);

  /// Records [message] at [LogLevel.error], with the caught object.
  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) => log(
    LogLevel.error,
    message,
    error: error,
    stackTrace: stackTrace,
    context: context,
  );
}
