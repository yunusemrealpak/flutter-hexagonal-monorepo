@Tags(['unit'])
library;

import 'package:core_ports/core_ports.dart';
import 'package:test/test.dart';

/// The narrowest possible implementation of [Logger]: one method. That it is
/// this small is the point of keeping the severity shorthands in an extension.
final class _RecordingLogger implements Logger {
  final List<({LogLevel level, String message, Object? error})> records = [];

  @override
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {
    records.add((level: level, message: message, error: error));
  }
}

void main() {
  test('the shorthands route to the single method the port declares', () {
    final logger = _RecordingLogger()
      ..debug('d')
      ..info('i')
      ..warning('w')
      ..error('e', error: const FormatException('boom'));

    expect(
      logger.records.map((r) => r.level),
      [LogLevel.debug, LogLevel.info, LogLevel.warning, LogLevel.error],
    );
    expect(logger.records.last.error, isA<FormatException>());
  });

  test('severities are ordered least to most severe', () {
    expect(
      LogLevel.values,
      [LogLevel.debug, LogLevel.info, LogLevel.warning, LogLevel.error],
    );
    expect(LogLevel.debug.index, lessThan(LogLevel.error.index));
  });
}
