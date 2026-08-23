import 'package:opentelemetry/api.dart' as otel;

/// Turns the loosely typed property maps the ports accept into OpenTelemetry
/// attributes.
///
/// The ports take `Map<String, Object?>` because a caller should not have to
/// think about a telemetry vocabulary while writing a use case. OpenTelemetry
/// accepts a closed set of attribute types. This function is where the two
/// meet, and it is exported because both adapters here need it and so does any
/// `_infrastructure` package that decorates its own spans.
///
/// Two decisions are worth naming. A `null` value is dropped rather than
/// encoded as the string `"null"`: an attribute that is absent is queryable as
/// absent, while one that says `"null"` pollutes every aggregation over that
/// key. Anything outside the supported types is stringified rather than
/// dropped, because a value the developer thought was worth recording should
/// reach the backend even if its type did not survive.
List<otel.Attribute> otelAttributes(Map<String, Object?> source) {
  final attributes = <otel.Attribute>[];
  for (final entry in source.entries) {
    final key = entry.key;
    switch (entry.value) {
      case null:
        continue;
      case final String value:
        attributes.add(otel.Attribute.fromString(key, value));
      case final bool value:
        attributes.add(otel.Attribute.fromBoolean(key, value));
      case final int value:
        attributes.add(otel.Attribute.fromInt(key, value));
      case final double value:
        attributes.add(otel.Attribute.fromDouble(key, value));
      case final List<String> value:
        attributes.add(otel.Attribute.fromStringList(key, value));
      case final DateTime value:
        // ISO-8601 in UTC, matching how timestamps are stored in
        // storage_drift. A backend that receives two representations of the
        // same instant cannot correlate them.
        attributes.add(
          otel.Attribute.fromString(key, value.toUtc().toIso8601String()),
        );
      case final Object value:
        attributes.add(otel.Attribute.fromString(key, value.toString()));
    }
  }
  return attributes;
}
