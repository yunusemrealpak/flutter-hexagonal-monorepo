@Tags(['unit'])
library;

import 'package:analytics_otel/analytics_otel.dart';
import 'package:core_testing/core_testing.dart';
import 'package:fixnum/fixnum.dart';
import 'package:opentelemetry/api.dart' as api;
import 'package:test/test.dart';

import '_recording_tracer.dart';

void main() {
  late RecordingSpanExporter exporter;
  late FakeClock clock;
  late OtelAnalyticsSink sink;

  setUp(() {
    exporter = RecordingSpanExporter();
    clock = FakeClock();
    sink = OtelAnalyticsSink(recordingTracer(exporter, clock));
  });

  group('OtelAnalyticsSink.track', () {
    test('emits one span named after the event', () {
      sink.track('shipment_assigned');

      expect(exporter.spans, hasLength(1));
      expect(exporter.spans.single.name, 'shipment_assigned');
    });

    test('carries properties through as attributes', () {
      sink.track(
        'shipment_assigned',
        properties: {'attempts': 2, 'offline': true, 'region': 'TR-34'},
      );

      final attributes = exporter.spans.single.attributes;
      expect(attributes.get('attempts'), 2);
      expect(attributes.get('offline'), true);
      expect(attributes.get('region'), 'TR-34');
    });

    test('stamps the span from the injected clock', () {
      clock.advance(const Duration(hours: 2));

      sink.track('shipment_assigned');

      // Rule A1 reaching one layer further than it can on its own: the SDK
      // reads a clock internally, and ClockTimeProvider is the seam that makes
      // that clock the one the test chose.
      expect(
        exporter.spans.single.startTime.toInt(),
        clock.now().microsecondsSinceEpoch * 1000,
      );
    });
  });

  group('OtelAnalyticsSink.identify', () {
    test('attributes later events to the actor', () {
      sink
        ..identify('CUR-9', traits: {'role': 'courier'})
        ..track('shift_started');

      final attributes = exporter.spans.single.attributes;
      expect(attributes.get('actor.id'), 'CUR-9');
      expect(attributes.get('role'), 'courier');
    });

    test('does not reach back to events already recorded', () {
      sink
        ..track('app_opened')
        ..identify('CUR-9');

      expect(exporter.spans.single.attributes.get('actor.id'), isNull);
    });

    test('reset stops attributing events to the previous actor', () {
      sink
        ..identify('CUR-9', traits: {'role': 'courier'})
        ..reset()
        ..track('app_opened');

      // Sign-out on a device several couriers share during a shift. Getting
      // this wrong attributes one person's work to another.
      final attributes = exporter.spans.single.attributes;
      expect(attributes.get('actor.id'), isNull);
      expect(attributes.get('role'), isNull);
    });
  });

  group('OtelAnalyticsSink failure handling', () {
    test('never lets a broken pipeline reach the caller', () {
      final broken = OtelAnalyticsSink(_ThrowingTracer());

      // The port declares no Future and no Result: a caller must not be able
      // to observe that telemetry failed. Losing an event is the correct
      // trade against failing a delivery.
      expect(() => broken.track('shipment_assigned'), returnsNormally);
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
    Int64? startTime,
  }) => throw StateError('collector unreachable');
}
