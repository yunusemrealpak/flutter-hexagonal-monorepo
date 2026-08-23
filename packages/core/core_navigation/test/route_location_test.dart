@Tags(['unit'])
library;

import 'package:core_navigation/core_navigation.dart';
import 'package:test/test.dart';

void main() {
  test('a location with no query encodes to its path', () {
    expect(RouteLocation('/shipments').value, '/shipments');
  });

  test('query parameters are encoded', () {
    final location = RouteLocation(
      '/shipments',
      queryParameters: {'status': 'out for delivery'},
    );

    expect(location.value, '/shipments?status=out+for+delivery');
  });

  test('parameter order does not change identity', () {
    final first = RouteLocation(
      '/shipments',
      queryParameters: {'status': 'assigned', 'zone': 'north'},
    );
    final second = RouteLocation(
      '/shipments',
      queryParameters: {'zone': 'north', 'status': 'assigned'},
    );

    expect(first, second);
    expect(first.hashCode, second.hashCode);
  });

  test('different destinations are not equal', () {
    expect(RouteLocation('/shipments'), isNot(RouteLocation('/routes')));
  });

  test('deduplicating a double tap is a value comparison', () {
    final tapped = [
      RouteLocation('/shipments/s-1'),
      RouteLocation('/shipments/s-1'),
      RouteLocation('/shipments/s-2'),
    ];

    expect(tapped.toSet(), hasLength(2));
  });

  test('keeps the parameters it was given for the router to consume', () {
    final location = RouteLocation(
      '/shipments',
      queryParameters: {'zone': 'north'},
    );

    expect(location.path, '/shipments');
    expect(location.queryParameters, {'zone': 'north'});
  });
}
