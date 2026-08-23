import 'package:core_ports/core_ports.dart';
import 'log_record.dart';

/// A [Logger] that keeps what it was told.
///
/// Useful for the handful of assertions where logging *is* the behaviour —
/// that an adapter records the failure it swallowed, that a retry says which
/// attempt it is on. Do not assert on log messages as a proxy for behaviour
/// that has a better observable; a test that breaks when someone improves the
/// wording of a log line is a test that costs more than it earns.
final class RecordingLogger implements Logger {
  final List<LogRecord> _records = [];

  /// Everything logged so far, oldest first.
  List<LogRecord> get records => List.unmodifiable(_records);

  /// Everything logged at [level].
  List<LogRecord> recordsAt(LogLevel level) =>
      _records.where((record) => record.level == level).toList();

  /// Forgets everything recorded so far.
  void clear() => _records.clear();

  @override
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {
    _records.add(
      LogRecord(
        level: level,
        message: message,
        error: error,
        stackTrace: stackTrace,
        context: context,
      ),
    );
  }
}
