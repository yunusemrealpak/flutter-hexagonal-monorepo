import 'package:core_testing/src/recording_analytics_sink.dart';

/// One call captured by a [RecordingAnalyticsSink].
///
/// Sealed, so a test that switches over the recorded calls is told by the
/// compiler when a new kind of call is added.
sealed class AnalyticsRecord {
  const AnalyticsRecord();
}

/// A captured `track` call.
final class TrackedEvent extends AnalyticsRecord {
  /// Captures an event and its properties.
  const TrackedEvent(this.event, {this.properties = const {}});

  /// The event name.
  final String event;

  /// The properties attached to it.
  final Map<String, Object?> properties;

  @override
  String toString() => 'TrackedEvent($event, $properties)';
}

/// A captured `identify` call.
final class IdentifiedActor extends AnalyticsRecord {
  /// Captures the actor identifier and its traits.
  const IdentifiedActor(this.actorId, {this.traits = const {}});

  /// The opaque actor identifier.
  final String actorId;

  /// The non-identifying traits attached to it.
  final Map<String, Object?> traits;

  @override
  String toString() => 'IdentifiedActor($actorId, $traits)';
}

/// A captured `reset` call.
final class ResetIdentity extends AnalyticsRecord {
  /// Captures that the actor association was dropped.
  const ResetIdentity();

  @override
  String toString() => 'ResetIdentity()';
}
