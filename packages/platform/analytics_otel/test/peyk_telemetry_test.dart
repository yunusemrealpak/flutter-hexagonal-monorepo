@Tags(['unit'])
library;

import 'package:analytics_otel/analytics_otel.dart';
import 'package:core_testing/core_testing.dart';
import 'package:fixnum/fixnum.dart';
import 'package:opentelemetry/api.dart' as api;
import 'package:opentelemetry/sdk.dart' as sdk;
import 'package:test/test.dart';

/// A [sdk.SpanExporter] that keeps what it is given.
///
/// Nothing in this file asserts on it, and that is deliberate rather than an
/// oversight: a `BatchSpanProcessor` exports on a five-second timer, and a
/// test that waited for one would be a test about `Timer.periodic`. It exists
/// so that installing a provider in a test opens no socket.
final class _NullExporter implements sdk.SpanExporter {
  @override
  void export(List<sdk.ReadOnlySpan> spans) {}

  @override
  void forceFlush() {}

  @override
  void shutdown() {}
}

void main() {
  // One test rather than several, because the property worth proving is a
  // *transition* and the global it turns on can only be turned on once per
  // process. Split into two tests, whichever ran second would assert against a
  // provider the other had already installed.
  test('installing turns the workspace-wide no-op into a real provider', () {
    final clock = FakeClock(DateTime.utc(2026, 3, 1, 8, 30));

    // Before. This is exactly what both applications shipped: nobody had
    // called the registrar, so the library answered its no-op provider, whose
    // spans carry an invalid context and are dropped inside the library. It is
    // also the branch `OtelLogger` reads — `spanFromContext(...).isValid` — so
    // an invalid context here means every record it wrote became a detached
    // span rather than an event on the operation that produced it.
    expect(
      api.globalTracerProvider
          .getTracer('peyk.test')
          .startSpan('before')
          .spanContext
          .isValid,
      isFalse,
      reason: 'the library starts out with a no-op provider',
    );

    expect(PeykTelemetry.isInstalled, isFalse);

    final installed = PeykTelemetry.install(
      exporter: _NullExporter(),
      serviceName: 'peyk.test',
      serviceVersion: '1.2.3',
      clock: clock,
    );

    expect(installed, isTrue);
    expect(PeykTelemetry.isInstalled, isTrue);

    final span = api.globalTracerProvider
        .getTracer('peyk.test')
        .startSpan('after');

    expect(
      span.spanContext.isValid,
      isTrue,
      reason: 'a registered SDK provider mints real trace and span ids',
    );

    // And the span is stamped from the injected clock rather than from the
    // system one. That is rule A1 kept past the package boundary: the library
    // reads a clock internally, `ClockTimeProvider` is the seam it offers, and
    // until a provider was installed nothing in the workspace ever handed it
    // over.
    expect(
      (span as sdk.ReadOnlySpan).startTime,
      Int64(clock.now().microsecondsSinceEpoch) * 1000,
    );

    span.end();

    // A second call is a no-op rather than a throw. The library's own
    // registrar throws, and a flavoured build with two entry points would
    // otherwise crash on start-up for a condition nobody can act on.
    expect(
      PeykTelemetry.install(
        exporter: _NullExporter(),
        serviceName: 'peyk.test',
        clock: clock,
      ),
      isFalse,
    );
  });

  test('the collector exporter is addressed, never defaulted', () {
    // The same rule as `PeykTransport.optionsFor`: an endpoint this package
    // could supply is an endpoint a call site could get wrong, so there is no
    // parameterless way to obtain one.
    final exporter = PeykTelemetry.collectorAt(
      Uri.parse('https://otel.peyk.test/v1/traces'),
    );

    expect(exporter, isA<sdk.CollectorExporter>());
    expect(
      (exporter as sdk.CollectorExporter).uri.toString(),
      'https://otel.peyk.test/v1/traces',
    );
  });
}
