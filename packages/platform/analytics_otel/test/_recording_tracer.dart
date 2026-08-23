import 'package:analytics_otel/analytics_otel.dart';
import 'package:core_testing/core_testing.dart';
import 'package:opentelemetry/api.dart' as api;
import 'package:opentelemetry/sdk.dart' as sdk;

/// A span exporter that keeps what it was given.
///
/// The whole pipeline is real — tracer, processor, exporter — because the
/// thing under test is what the adapters put on a span, and a test that
/// inspected the adapter's internal state instead would keep passing after
/// the day the attribute stopped reaching the exporter.
final class RecordingSpanExporter implements sdk.SpanExporter {
  /// Every span exported so far, oldest first.
  final List<sdk.ReadOnlySpan> spans = [];

  @override
  void export(List<sdk.ReadOnlySpan> spans) => this.spans.addAll(spans);

  // Still on the SpanExporter interface in 0.18, removed in 0.19.
  @override
  void forceFlush() {}

  @override
  void shutdown() {}
}

/// A tracer wired to [exporter], with span times coming from [clock].
api.Tracer recordingTracer(RecordingSpanExporter exporter, FakeClock clock) {
  return sdk.TracerProviderBase(
    processors: [sdk.SimpleSpanProcessor(exporter)],
    timeProvider: ClockTimeProvider(clock),
  ).getTracer('peyk.test');
}
