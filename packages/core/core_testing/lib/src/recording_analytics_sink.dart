import 'package:core_ports/core_ports.dart';
import 'analytics_record.dart';

/// An [AnalyticsSink] that keeps every call in order.
///
/// Analytics is one of the few places where "was this called?" is the actual
/// requirement rather than a proxy for one — a product decision usually rests
/// on an event being emitted exactly once with exactly these properties.
///
/// It is also where a privacy regression is easiest to catch. Asserting that
/// the properties of a delivery event contain no consignee name is a one-line
/// test here and an audit finding otherwise.
final class RecordingAnalyticsSink implements AnalyticsSink {
  final List<AnalyticsRecord> _records = [];

  /// Every call so far, oldest first.
  List<AnalyticsRecord> get records => List.unmodifiable(_records);

  /// Just the tracked events.
  List<TrackedEvent> get events => _records.whereType<TrackedEvent>().toList();

  /// The names of the tracked events, in order.
  List<String> get eventNames => events.map((event) => event.event).toList();

  @override
  void track(String event, {Map<String, Object?> properties = const {}}) =>
      _records.add(TrackedEvent(event, properties: properties));

  @override
  void identify(String actorId, {Map<String, Object?> traits = const {}}) =>
      _records.add(IdentifiedActor(actorId, traits: traits));

  @override
  void reset() => _records.add(const ResetIdentity());
}
