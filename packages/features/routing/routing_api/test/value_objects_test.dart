@Tags(['unit'])
library;

import 'package:routing_api/routing_api.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  group('GeoPoint', () {
    test('refuses coordinates that are not on the earth', () {
      expect(GeoPoint.at(latitude: 91, longitude: 0).isFailure, isTrue);
      expect(GeoPoint.at(latitude: 0, longitude: 181).isFailure, isTrue);
      expect(GeoPoint.at(latitude: double.nan, longitude: 0).isFailure, isTrue);
    });

    test('accepts the poles and the antimeridian', () {
      expect(GeoPoint.at(latitude: 90, longitude: 180).isSuccess, isTrue);
      expect(GeoPoint.at(latitude: -90, longitude: -180).isSuccess, isTrue);
    });

    test('measures a known distance', () {
      // A hundredth of a degree of latitude is about 1.11 km anywhere on
      // earth. Asserting against a number that can be checked by hand is what
      // makes this test a test rather than a record of whatever the code did.
      final metres = depot.distanceTo(near(north: 0.01));

      expect(metres, closeTo(1112, 5));
    });

    test('a degree of longitude is shorter away from the equator', () {
      // The mistake this catches is a haversine that forgot cos(latitude).
      // Istanbul is at about 41 degrees north, where a degree of longitude is
      // roughly three quarters of a degree of latitude.
      final northSouth = depot.distanceTo(near(north: 0.01));
      final eastWest = depot.distanceTo(near(east: 0.01));

      expect(eastWest, lessThan(northSouth));
      expect(eastWest / northSouth, closeTo(0.755, 0.02));
    });

    test('is symmetric, and zero to itself', () {
      final other = near(east: 0.02, north: 0.01);

      expect(depot.distanceTo(other), closeTo(other.distanceTo(depot), 0.001));
      expect(depot.distanceTo(depot), closeTo(0, 0.001));
    });
  });

  group('ServiceTime', () {
    test('refuses a negative duration', () {
      expect(
        ServiceTime.of(const Duration(minutes: -1)).isFailure,
        isTrue,
      );
    });

    test('refuses one no stop could take', () {
      // A service time of a day, arriving from a mis-parsed field, would push
      // every subsequent estimate past midnight and make a route look
      // infeasible for a reason nobody could find.
      expect(ServiceTime.of(const Duration(days: 1)).isFailure, isTrue);
    });

    test('accepts zero, because some stops are a letterbox', () {
      expect(ServiceTime.of(Duration.zero).isSuccess, isTrue);
    });
  });

  group('TravelWindow', () {
    final opens = DateTime.utc(2026, 3, 14, 9);
    final closes = DateTime.utc(2026, 3, 14, 18);

    test('refuses a window that closes before it opens', () {
      expect(
        TravelWindow.between(opensAt: closes, closesAt: opens).isFailure,
        isTrue,
      );
    });

    test('includes both ends', () {
      // A courier who arrives exactly at closing time is on time. A boundary
      // that said otherwise would fail a delivery on a rounding difference
      // between two clocks.
      final window = unwrap(
        TravelWindow.between(opensAt: opens, closesAt: closes),
      );

      expect(window.admits(opens), isTrue);
      expect(window.admits(closes), isTrue);
      expect(window.admits(closes.add(const Duration(seconds: 1))), isFalse);
    });

    test('separates arriving early from arriving late', () {
      // Arriving early is a wait, not a failure. Collapsing the two would make
      // an optimiser treat a courier ahead of schedule as one who has missed a
      // delivery.
      final window = unwrap(
        TravelWindow.between(opensAt: opens, closesAt: closes),
      );
      final early = opens.subtract(const Duration(minutes: 30));

      expect(window.isLateAt(early), isFalse);
      expect(window.waitFrom(early), const Duration(minutes: 30));
      expect(window.isLateAt(closes.add(const Duration(minutes: 1))), isTrue);
      expect(window.waitFrom(closes), Duration.zero);
    });
  });

  group('TrafficProfile', () {
    test('refuses a speed that would take forever or no time', () {
      expect(
        TrafficProfile.of(freeFlowKmh: 0, congestion: 1).isFailure,
        isTrue,
      );
      expect(
        TrafficProfile.of(freeFlowKmh: -10, congestion: 1).isFailure,
        isTrue,
      );
    });

    test('refuses a congestion multiplier below free flow', () {
      // Below 1 would mean traffic makes a journey faster, which is not a
      // thing a traffic service reports and not a thing an estimate should be
      // able to express.
      expect(
        TrafficProfile.of(freeFlowKmh: 30, congestion: 0.5).isFailure,
        isTrue,
      );
    });

    test('turns a distance into a time', () {
      // 30 km/h over 15 km is half an hour.
      expect(
        TrafficProfile.assumed.timeFor(15000),
        const Duration(minutes: 30),
      );
    });

    test('congestion multiplies the time rather than dividing the speed', () {
      final busy = unwrap(
        TrafficProfile.of(freeFlowKmh: 30, congestion: 2),
      );

      expect(busy.timeFor(15000), const Duration(hours: 1));
    });
  });

  group('StopSequence', () {
    final stops = [stopAt('a'), stopAt('b', east: 0.01)];

    test('accepts an order that names every stop once', () {
      expect(
        StopSequence.over(stops, [stops[1].id, stops[0].id]).isSuccess,
        isTrue,
      );
    });

    test('refuses a stop that appears twice', () {
      expect(
        StopSequence.over(stops, [stops[0].id, stops[0].id]).isFailure,
        isTrue,
      );
    });

    test('refuses an order that misses a stop', () {
      // Which is a parcel nobody delivers, and nobody finds out until the
      // depot counts.
      final refused = StopSequence.over(stops, [stops[0].id]);

      expect(refused.isFailure, isTrue);
      expect(
        refused.fold((_) => '', (f) => '$f'),
        contains('nothing visits b'),
      );
    });

    test('refuses a stop that is not on the route', () {
      final stranger = stopAt('c', north: 0.01);

      expect(
        StopSequence.over(stops, [
          stops[0].id,
          stops[1].id,
          stranger.id,
        ]).isFailure,
        isTrue,
      );
    });

    test('an empty route is a route', () {
      // A courier with no assignments is having an ordinary morning, not an
      // error.
      expect(StopSequence.over(const [], const []).isSuccess, isTrue);
      expect(StopSequence.empty.isEmpty, isTrue);
    });

    test('knows what comes next', () {
      final order = sequence(stops, ['a', 'b']);

      expect(order.first, stops[0].id);
      expect(order.after(stops[0].id), stops[1].id);
      expect(order.after(stops[1].id), isNull);
      expect(order.positionOf(stops[1].id), 1);
    });

    test('two sequences with the same order are equal', () {
      expect(sequence(stops, ['a', 'b']), sequence(stops, ['a', 'b']));
      expect(sequence(stops, ['a', 'b']), isNot(sequence(stops, ['b', 'a'])));
    });
  });

  group('Stop', () {
    test('reports the one it cannot place, by name', () {
      // A route planned around a guessed coordinate sends a courier to the
      // wrong street with full confidence.
      final placed = ungeocoded('a').placed;

      expect(placed.isFailure, isTrue);
      expect(placed.fold((_) => '', (f) => '$f'), contains('a'));
    });

    test('a stop with no window is never late', () {
      expect(stopAt('a').isLateAt(noon.add(const Duration(days: 1))), isFalse);
    });
  });
}
