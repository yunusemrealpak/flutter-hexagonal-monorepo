import 'package:core_ports/core_ports.dart';
import 'recording_logger.dart';

/// One entry captured by a [RecordingLogger].
final class LogRecord {
  /// Captures a log call verbatim.
  const LogRecord({
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
    this.context = const {},
  });

  /// The severity the caller used.
  final LogLevel level;

  /// The message the caller passed.
  final String message;

  /// The caught object, when the caller supplied one.
  final Object? error;

  /// The stack trace, when the caller supplied one.
  final StackTrace? stackTrace;

  /// The structured fields the caller attached.
  final Map<String, Object?> context;

  @override
  String toString() => '[${level.name}] $message';
}
