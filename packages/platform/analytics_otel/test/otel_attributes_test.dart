@Tags(['unit'])
library;

import 'package:analytics_otel/analytics_otel.dart';
import 'package:opentelemetry/api.dart' as otel;
import 'package:test/test.dart';

Object? _valueOf(List<otel.Attribute> attributes, String key) {
  for (final attribute in attributes) {
    if (attribute.key == key) {
      return attribute.value;
    }
  }
  return null;
}

void main() {
  group('otelAttributes', () {
    test('carries each supported type through unchanged', () {
      final attributes = otelAttributes({
        'region': 'TR-34',
        'attempts': 3,
        'ratio': 0.5,
        'offline': true,
        'tags': ['urgent', 'fragile'],
      });

      expect(_valueOf(attributes, 'region'), 'TR-34');
      expect(_valueOf(attributes, 'attempts'), 3);
      expect(_valueOf(attributes, 'ratio'), 0.5);
      expect(_valueOf(attributes, 'offline'), true);
      expect(_valueOf(attributes, 'tags'), ['urgent', 'fragile']);
    });

    test('drops a null rather than encoding it as text', () {
      final attributes = otelAttributes({'region': null, 'attempts': 1});

      // An absent attribute is queryable as absent. One that says "null"
      // pollutes every aggregation over that key.
      expect(attributes, hasLength(1));
      expect(_valueOf(attributes, 'region'), isNull);
    });

    test('writes a DateTime as ISO-8601 in UTC', () {
      final attributes = otelAttributes({
        'capturedAt': DateTime.utc(2026, 1, 1, 9),
      });

      // The same representation storage_drift persists. A backend that
      // receives two spellings of one instant cannot correlate them.
      expect(_valueOf(attributes, 'capturedAt'), '2026-01-01T09:00:00.000Z');
    });

    test('stringifies anything else rather than losing it', () {
      final attributes = otelAttributes({'state': const Duration(seconds: 30)});

      // A value the developer thought worth recording reaches the backend even
      // when its type did not survive.
      expect(_valueOf(attributes, 'state'), '0:00:30.000000');
    });
  });
}
