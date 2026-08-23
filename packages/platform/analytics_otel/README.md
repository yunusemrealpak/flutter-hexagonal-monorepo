# analytics_otel

OpenTelemetry adapters for the observability ports, plus the time provider that keeps span timestamps deterministic.

## What it is for

| Type | Implements | Role |
|---|---|---|
| `OtelAnalyticsSink` | `core_ports.AnalyticsSink` | a tracked event becomes a zero-duration span |
| `OtelLogger` | `core_ports.Logger` | a record becomes an event on the active span |
| `ClockTimeProvider` | `opentelemetry.TimeProvider` | spans are stamped from the `Clock` port |
| `otelAttributes` | — | `Map<String, Object?>` → OpenTelemetry attributes |

Two of the eleven core ports are implemented in one package, which looks like a merge and is not. In an OpenTelemetry pipeline analytics and logging are the same thing seen twice: both become spans, both carry the same trace identifier, and they are read together — a funnel drop-off can be held against the latency of the request underneath it. Splitting them across two packages would mean two tracers, two configurations, and two chances for the trace identifiers to disagree.

## What it may depend on

`core_ports`, `opentelemetry` and `fixnum`. Not `core_kernel` — nothing here returns a `Result`, because neither port can fail from a caller's point of view.

## What must never live here

- **A collector endpoint, an API key, or a sampling rate.** They are configured on the `TracerProvider` the composition root builds and hands in.
- **Domain vocabulary.** Event names arrive as strings from the features that emit them. This package must not know what a shipment is.
- **Anything that can be observed to fail.** Both adapters swallow what they catch, which is only safe because nothing here is load-bearing.
- **Personally identifying data.** The port's documentation says it and it bears repeating: nothing beyond the opaque actor identifier. A courier platform handles other people's data all day, and an analytics pipeline is the easiest place for it to leak out of the system.

## Three decisions worth knowing about

**Failure is swallowed, deliberately.** `AnalyticsSink` and `Logger` declare no `Future` and no `Result`. That is a contract, not an omission: a caller must not be able to observe that telemetry failed, because the moment it can, it will start handling it. Losing an event is the correct trade — the alternative is a courier who cannot complete a delivery because a collector endpoint moved.

**`ClockTimeProvider` is how rule A1 reaches past the package boundary.** A1 forbids *product code* from calling `DateTime.now()`; a third-party library that reads the clock internally is outside its reach. OpenTelemetry offers a seam for time, so taking it is what keeps the rule meaning something — and it is what lets a test assert a span's start time exactly rather than approximately.

**A log record outside a span still lands.** Inside one, the record becomes a span event, which is the entire reason to log into a tracing pipeline: the line is read in the context of the request that produced it rather than next to nine hundred lines interleaved by time. Outside one, it becomes a zero-duration span of its own, so nothing is silently dropped. When the Dart SDK grows a logs API that branch becomes a `LogRecord` and nothing above the port changes.
