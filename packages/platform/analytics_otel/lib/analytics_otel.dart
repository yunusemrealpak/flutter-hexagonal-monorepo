/// OpenTelemetry adapters for the observability ports.
///
/// Two of `core_ports`' eleven ports are implemented here — `AnalyticsSink`
/// and `Logger` — because in an OpenTelemetry pipeline they are the same
/// thing seen twice. A tracked event and a log line both become spans, carry
/// the same trace identifier, and are read together: a funnel drop-off can be
/// held against the latency of the request underneath it, which is impossible
/// when product analytics and technical logs live in two systems.
///
/// Neither port can fail from a caller's point of view, and both adapters take
/// that literally: what they catch, they swallow. Losing an event is the
/// correct trade. The alternative is a courier who cannot complete a delivery
/// because a telemetry endpoint moved.
///
/// `PeykTelemetry` is what makes the other three do anything at all, and its
/// absence was the largest hole this package ever had. `globalTracerProvider`
/// answers a no-op provider until `registerGlobalTracerProvider` is called;
/// both applications read the getter and neither called the registrar, so
/// every span this package produced was discarded inside the library — with
/// nothing failing and nothing logging to say so.
///
/// `ClockTimeProvider` is the fourth thing here and the least obvious. Rule A1
/// forbids product code from reading the system clock; a third-party library
/// that reads it internally is out of the rule's reach. OpenTelemetry offers a
/// seam for it, so taking that seam is how the rule keeps meaning something
/// past the package boundary — and it is what makes a span's start time a
/// value a test can state.
library;

export 'src/clock_time_provider.dart';
export 'src/otel_analytics_sink.dart';
export 'src/otel_attributes.dart';
export 'src/otel_logger.dart';
export 'src/peyk_telemetry.dart';
