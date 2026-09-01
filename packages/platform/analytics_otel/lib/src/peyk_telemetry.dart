import 'package:core_ports/core_ports.dart';
import 'package:opentelemetry/api.dart' as api;
import 'package:opentelemetry/sdk.dart' as sdk;

import 'clock_time_provider.dart';

/// Registers the tracer provider the adapters in this package write into.
///
/// **Without this call the whole package is a no-op**, and that was the state
/// of the workspace until it existed. `globalTracerProvider` answers
/// `NoopTracerProvider` until `registerGlobalTracerProvider` is called; both
/// applications read the getter and never called the registrar, so every span
/// `OtelAnalyticsSink` started and every record `OtelLogger` wrote was
/// discarded inside the library. Nothing failed, nothing logged, and the test
/// suite could not see it because tests assert against `RecordingLogger`
/// rather than against a pipeline.
///
/// ## The ordering hazard is real, and the library enforces it
///
/// `registerGlobalTracerProvider` throws a `StateError` if a provider is
/// already set, and the library sets one the first time anything *reads*
/// `globalTracerProvider`. So [install] has to run before the composition root
/// asks for a tracer — before `getTracer`, not merely before the first span.
/// An application that installs after building its platform object gets an
/// exception at start-up rather than silent telemetry, which is the better of
/// the two failures but still a start-up crash.
///
/// ## What is deliberately not decided here
///
/// **Where the spans go.** [install] takes a [sdk.SpanExporter] rather than a
/// URL, for the same reason `PeykTransport.optionsFor` takes a base URL rather
/// than holding one: an endpoint this package could supply is an endpoint a
/// call site could get wrong. [collectorAt] builds the usual one.
///
/// **When they go.** A [sdk.BatchSpanProcessor] batches and exports on a
/// timer, which is the only tenable choice on a handset — a span per request
/// over a courier's connection would cost more than the request it describes.
final class PeykTelemetry {
  const PeykTelemetry._();

  static bool _installed = false;

  /// Whether a provider has been registered by this class.
  static bool get isInstalled => _installed;

  /// Registers a tracer provider that exports through [exporter].
  ///
  /// Answers `true` when it registered and `false` when a provider was already
  /// installed. The second call is a no-op rather than a throw because the
  /// condition it describes — "telemetry is already running" — is not a fault
  /// a caller can act on, and because the alternative is a start-up crash on
  /// the second entry point of a flavoured build.
  ///
  /// [clock] stamps every span through [ClockTimeProvider]: rule A1 reaches
  /// past the package boundary wherever the library offers a seam, and this is
  /// the seam.
  static bool install({
    required sdk.SpanExporter exporter,
    required String serviceName,
    required Clock clock,
    String serviceVersion = 'unversioned',
    String? deploymentEnvironment,
  }) {
    if (_installed) return false;

    api.registerGlobalTracerProvider(
      sdk.TracerProviderBase(
        processors: [sdk.BatchSpanProcessor(exporter)],
        // The three attributes every backend groups by. Without them a span
        // says what happened and not which application it happened in, and two
        // apps reporting into one collector become one indistinguishable
        // stream.
        resource: sdk.Resource([
          api.Attribute.fromString('service.name', serviceName),
          api.Attribute.fromString('service.version', serviceVersion),
          if (deploymentEnvironment != null)
            api.Attribute.fromString(
              'deployment.environment',
              deploymentEnvironment,
            ),
        ]),
        timeProvider: ClockTimeProvider(clock),
      ),
    );

    _installed = true;
    return true;
  }

  /// The exporter that posts OTLP over HTTP to a collector at [endpoint].
  ///
  /// A named constructor rather than a parameter of [install] so that a test
  /// can install a recording exporter and never open a socket — the same shape
  /// `FakeHttpTransport` gives the transport.
  static sdk.SpanExporter collectorAt(
    Uri endpoint, {
    Map<String, String> headers = const {},
  }) => sdk.CollectorExporter(endpoint, headers: headers);
}
