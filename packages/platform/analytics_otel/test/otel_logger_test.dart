@Tags(['unit'])
library;

// `api.zone` is how a span is made the ambient one in 0.18, and the SDK marks
// it experimental while the alternative — `Context.execute` — is deprecated in
// favour of it. Suppressed here rather than at the call site because the
// formatter splits the expression across lines and an `ignore` comment only
// covers the line that follows it.
// ignore_for_file: experimental_member_use

import 'package:analytics_otel/analytics_otel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:core_testing/core_testing.dart';
import 'package:opentelemetry/api.dart' as api;
import 'package:test/test.dart';

import '_recording_tracer.dart';

void main() {
  late RecordingSpanExporter exporter;
  late FakeClock clock;
  late api.Tracer tracer;

  setUp(() {
    exporter = RecordingSpanExporter();
    clock = FakeClock();
    tracer = recordingTracer(exporter, clock);
  });

  group('OtelLogger outside a span', () {
    test('records a message as a span of its own', () {
      OtelLogger(tracer).info('outbox drained', context: {'entries': 4});

      expect(exporter.spans.single.name, 'outbox drained');
      expect(exporter.spans.single.attributes.get('log.severity'), 'info');
      expect(exporter.spans.single.attributes.get('entries'), 4);
    });

    test('drops anything below the minimum level', () {
      OtelLogger(tracer, minimumLevel: LogLevel.warning)
        ..debug('cache hit')
        ..info('outbox drained')
        ..warning('retrying');

      // The check lives in the adapter so that a caller never has to ask "is
      // debug on?" before writing a line.
      expect(exporter.spans.map((span) => span.name), ['retrying']);
    });

    test('attaches a caught error to the record', () {
      OtelLogger(tracer).error(
        'assignment rejected',
        error: StateError('shipment locked'),
        stackTrace: StackTrace.empty,
      );

      final span = exporter.spans.single;
      // An error recorded as an exception is searchable as one; an error
      // interpolated into the message is a line of text that happens to
      // contain it.
      expect(span.events.map((event) => event.name), contains('exception'));
    });
  });

  group('OtelLogger inside a span', () {
    test('records the message as an event on the active span', () {
      final logger = OtelLogger(tracer);

      final parent = tracer.startSpan('assign shipment');
      // Making a span the ambient one is what the SDK's own `trace` helper
      // does internally.
      api
          .zone(api.contextWithSpan(api.Context.current, parent))
          .run(
            () => logger.info('gateway answered', context: {'status': 200}),
          );
      parent.end();

      // The reason to log into a tracing pipeline at all: the line is read in
      // the context of the request that produced it, not next to nine hundred
      // lines from other requests interleaved by time.
      expect(exporter.spans, hasLength(1));
      final event = exporter.spans.single.events.single;
      expect(event.name, 'gateway answered');
      expect(
        event.attributes.firstWhere((a) => a.key == 'status').value,
        200,
      );
    });
  });

  group('OtelLogger failure handling', () {
    test('never lets a broken pipeline reach the caller', () {
      expect(
        () => OtelLogger(_ThrowingTracer()).info('outbox drained'),
        returnsNormally,
      );
    });
  });
}

final class _ThrowingTracer implements api.Tracer {
  @override
  Never startSpan(
    String name, {
    api.Context? context,
    api.SpanKind kind = api.SpanKind.internal,
    List<api.Attribute> attributes = const [],
    List<api.SpanLink> links = const [],
    Object? startTime,
  }) => throw StateError('collector unreachable');
}
