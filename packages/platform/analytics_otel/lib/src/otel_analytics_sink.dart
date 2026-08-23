import 'package:core_ports/core_ports.dart';
import 'package:opentelemetry/api.dart' as otel;
import 'otel_attributes.dart';

/// The [AnalyticsSink] the shipped applications run on.
///
/// Every tracked event becomes a zero-duration span. That is the OpenTelemetry
/// idiom for something that happened rather than something that took time, and
/// it means product analytics and technical traces arrive in one pipeline with
/// one correlation identifier — a funnel drop-off can be read against the
/// latency of the request underneath it.
///
/// ## Nothing here can fail a use case
///
/// The port declares no `Future` and no `Result`, and that is a contract
/// rather than an omission: analytics must never fail a use case, never slow
/// one down, and never give a caller something to await. So every method
/// swallows what it catches. Losing an event is the correct trade — the
/// alternative is a courier unable to complete a delivery because a telemetry
/// endpoint moved.
///
/// ## What [identify] does, and what it deliberately does not
///
/// The actor identifier and its traits are attached to every subsequent span
/// as attributes. They are held in memory only, so a restart starts anonymous
/// until the next sign-in identifies again — which is the safer default for a
/// device several couriers may share during a shift.
///
/// Never pass anything here that identifies a person beyond the opaque actor
/// identifier. A courier platform handles other people's data all day, and an
/// analytics pipeline is the easiest place for it to leak out of the system.
final class OtelAnalyticsSink implements AnalyticsSink {
  /// Records events on the given tracer.
  OtelAnalyticsSink(this._tracer);

  final otel.Tracer _tracer;

  String? _actorId;
  Map<String, Object?> _traits = const {};

  @override
  void track(String event, {Map<String, Object?> properties = const {}}) {
    try {
      _tracer
          .startSpan(
            event,
            kind: otel.SpanKind.internal,
            attributes: [..._actorAttributes(), ...otelAttributes(properties)],
          )
          .end();
    } on Object {
      // Deliberately swallowed. See the class documentation: a caller must not
      // be able to observe that telemetry failed, because the moment it can,
      // it will start handling it.
    }
  }

  @override
  void identify(String actorId, {Map<String, Object?> traits = const {}}) {
    _actorId = actorId;
    _traits = Map.unmodifiable(traits);
  }

  @override
  void reset() {
    // Called on sign-out, so that the next actor's events are not attributed
    // to the previous one. On a shared device that is not a nicety.
    _actorId = null;
    _traits = const {};
  }

  List<otel.Attribute> _actorAttributes() {
    final actorId = _actorId;
    if (actorId == null) {
      return const [];
    }
    return [
      otel.Attribute.fromString('actor.id', actorId),
      ...otelAttributes(_traits),
    ];
  }
}
