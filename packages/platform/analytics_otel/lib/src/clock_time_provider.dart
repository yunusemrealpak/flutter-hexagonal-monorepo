import 'package:core_ports/core_ports.dart';
import 'package:fixnum/fixnum.dart';
import 'package:opentelemetry/sdk.dart' as otel;

/// The [otel.TimeProvider] that stamps spans from the [Clock] port.
///
/// OpenTelemetry's own provider reads the system clock, which would make every
/// span timestamp in the workspace unassertable — the one thing rule A1 exists
/// to prevent. Handing the SDK this instead means a test can state when a span
/// started rather than measure it, and it costs one adapter.
///
/// It also keeps the rule honest at the edge. A1 forbids *product code* from
/// calling `DateTime.now()`; a third-party library that reads the clock
/// internally is outside its reach. Where the library offers a seam, taking it
/// is how the rule keeps meaning something past the package boundary.
final class ClockTimeProvider implements otel.TimeProvider {
  /// Stamps spans from the given clock.
  const ClockTimeProvider(this._clock);

  final Clock _clock;

  @override
  Int64 get now =>
      // DateTime resolves to microseconds; OpenTelemetry expects nanoseconds.
      Int64(_clock.now().microsecondsSinceEpoch) * 1000;
}
