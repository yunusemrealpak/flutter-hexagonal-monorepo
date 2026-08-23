import 'package:core_ports/core_ports.dart';
import 'package:opentelemetry/api.dart' as otel;
import 'otel_attributes.dart';

/// The [Logger] the shipped applications run on.
///
/// A record written while an operation is in flight becomes an event on that
/// operation's span, which is the whole reason to log into a tracing pipeline:
/// the line is read in the context of the request that produced it rather than
/// next to nine hundred lines from other requests interleaved by time.
///
/// A record written outside any span becomes a zero-duration span of its own,
/// so nothing is silently dropped. When the Dart OpenTelemetry SDK grows a
/// logs API, that branch becomes a `LogRecord` and nothing above this class
/// changes — which is the point of the port.
///
/// [minimumLevel] is applied inside the adapter rather than at the call
/// sites. A caller that has to ask "is debug on?" before logging has been
/// given a second thing to get wrong, and the cheap check belongs where the
/// record is about to cost something.
final class OtelLogger implements Logger {
  /// Writes records through the given tracer, dropping anything below
  /// [minimumLevel].
  OtelLogger(this._tracer, {this.minimumLevel = LogLevel.info});

  final otel.Tracer _tracer;

  /// The least severe record this logger passes on.
  final LogLevel minimumLevel;

  @override
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {
    if (level.index < minimumLevel.index) {
      return;
    }
    try {
      final attributes = [
        otel.Attribute.fromString('log.severity', level.name),
        ...otelAttributes(context),
      ];
      final active = otel.spanFromContext(otel.Context.current);
      if (active.spanContext.isValid) {
        active.addEvent(message, attributes: attributes);
        if (error != null) {
          // recordException is what makes an error searchable as an error
          // rather than as a line of text that happens to contain one.
          active.recordException(
            error,
            stackTrace: stackTrace ?? StackTrace.empty,
          );
        }
        return;
      }
      final span = _tracer.startSpan(message, attributes: attributes);
      if (error != null) {
        span.recordException(error, stackTrace: stackTrace ?? StackTrace.empty);
      }
      span.end();
    } on Object {
      // Same contract as the analytics sink: logging never fails from the
      // caller's point of view. A use case must not change what it does
      // because a log line did not land.
    }
  }
}
