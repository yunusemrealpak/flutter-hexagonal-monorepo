@Tags(['unit'])
library;

import 'package:routing_api/routing_api.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  group('RoutePlan.of', () {
    test('refuses a sequence that does not describe its stops', () {
      final stops = [stopAt('a'), stopAt('b', east: 0.01)];
      final other = [stopAt('a'), stopAt('c', north: 0.01)];

      expect(
        RoutePlan.of(
          id: unwrap(RoutePlanId.parse('plan-1')),
          courier: courier(),
          origin: depot,
          stops: stops,
          sequence: sequence(other, ['a', 'c']),
          departAt: noon,
        ).isFailure,
        isTrue,
      );
    });

    test('refuses a route containing a stop it cannot place', () {
      final stops = [stopAt('a', east: 0.01), ungeocoded('b')];

      final plan = RoutePlan.of(
        id: unwrap(RoutePlanId.parse('plan-1')),
        courier: courier(),
        origin: depot,
        stops: stops,
        sequence: sequence(stops, ['a', 'b']),
        departAt: noon,
      );

      expect(plan.fold((_) => null, (f) => f), isA<StopNotGeocoded>());
    });

    test('an empty route finishes when it departs', () {
      final plan = planOver(const [], const []);

      expect(plan.finishesAt, noon);
      expect(plan.etas, isEmpty);
      expect(plan.nextStopAfter(const {}), isNull);
    });
  });

  group('the estimates', () {
    test('are computed from the order, the distance and the profile', () {
      // 30 km/h assumed, and a hundredth of a degree of latitude is 1.112 km,
      // so the first leg is about 2m14s and the stop adds five minutes.
      final stops = [stopAt('a', north: 0.01)];
      final plan = planOver(stops, ['a']);

      final eta = plan.etaFor(stops.single.id)!;
      expect(
        eta.arrivesAt.difference(noon).inSeconds,
        closeTo(133, 3),
      );
      expect(
        eta.departsAt.difference(eta.arrivesAt),
        const Duration(minutes: 5),
      );
    });

    test('accumulate along the route', () {
      final stops = [stopAt('a', north: 0.01), stopAt('b', north: 0.02)];
      final plan = planOver(stops, ['a', 'b']);

      final first = plan.etaFor(stops[0].id)!;
      final second = plan.etaFor(stops[1].id)!;

      expect(second.arrivesAt.isAfter(first.departsAt), isTrue);
      expect(plan.finishesAt, second.departsAt);
    });

    test('depend on the order, which is the whole point of optimising', () {
      final stops = [stopAt('near', north: 0.005), stopAt('far', north: 0.05)];

      final good = planOver(stops, ['near', 'far']);
      final bad = planOver(stops, ['far', 'near']);

      expect(good.finishesAt.isBefore(bad.finishesAt), isTrue);
    });

    test('include the wait for a window that has not opened', () {
      // And the wait goes into the departure as well, so the next leg starts
      // from when the courier actually left. Without that, every estimate
      // after the first early arrival is optimistic by the length of the wait.
      final opensLater = unwrap(
        TravelWindow.between(
          opensAt: noon.add(const Duration(hours: 1)),
          closesAt: noon.add(const Duration(hours: 2)),
        ),
      );
      final stops = [stopAt('a', north: 0.01, window: opensLater)];
      final plan = planOver(stops, ['a']);

      final eta = plan.etaFor(stops.single.id)!;
      expect(eta.arrivesAt.isBefore(opensLater.opensAt), isTrue);
      expect(
        eta.departsAt,
        opensLater.opensAt.add(const Duration(minutes: 5)),
      );
    });

    test('flag a stop the route already expects to miss', () {
      // A plan is allowed to contain one. Refusing to produce a route at all
      // would leave a courier with nothing on a morning that started badly.
      final closed = unwrap(
        TravelWindow.between(
          opensAt: noon.subtract(const Duration(hours: 2)),
          closesAt: noon.subtract(const Duration(hours: 1)),
        ),
      );
      final stops = [stopAt('a', north: 0.01, window: closed)];
      final plan = planOver(stops, ['a']);

      expect(plan.etaFor(stops.single.id)!.isLate, isTrue);
      expect(plan.lateStops, [stops.single.id]);
    });

    test('get slower when traffic does', () {
      final stops = [stopAt('a', north: 0.05)];
      final busy = unwrap(TrafficProfile.of(freeFlowKmh: 30, congestion: 3));

      final free = planOver(stops, ['a']);
      final jammed = planOver(stops, ['a'], traffic: busy);

      expect(jammed.finishesAt.isAfter(free.finishesAt), isTrue);
    });
  });

  group('identity', () {
    test('a resequenced plan is the same plan', () {
      // Equality by id: a plan whose order a dispatcher rearranged is still
      // the plan that was handed to the courier this morning.
      final stops = [stopAt('a', north: 0.01), stopAt('b', east: 0.01)];
      final plan = planOver(stops, ['a', 'b']);

      final moved = unwrap(plan.resequenced([stops[1].id, stops[0].id]));

      expect(moved, plan);
      expect(moved.sequence, isNot(plan.sequence));
    });
  });

  group('resequenced', () {
    final stops = [stopAt('a', north: 0.01), stopAt('b', east: 0.01)];

    test('recomputes the estimates', () {
      final plan = planOver(stops, ['a', 'b']);

      final moved = unwrap(plan.resequenced([stops[1].id, stops[0].id]));

      expect(
        moved.etaFor(stops[1].id)!.arrivesAt,
        isNot(plan.etaFor(stops[1].id)!.arrivesAt),
      );
    });

    test('refuses an order that drops a stop', () {
      final plan = planOver(stops, ['a', 'b']);

      expect(plan.resequenced([stops[0].id]).isFailure, isTrue);
    });

    test('refuses an order that repeats one', () {
      final plan = planOver(stops, ['a', 'b']);

      expect(
        plan.resequenced([stops[0].id, stops[0].id]).isFailure,
        isTrue,
      );
    });

    test('leaves the original untouched', () {
      final plan = planOver(stops, ['a', 'b']);

      final moved = unwrap(plan.resequenced([stops[1].id, stops[0].id]));

      expect(plan.sequence.order.first, stops[0].id);
      expect(moved.sequence.order.first, stops[1].id);
    });
  });

  group('nextStopAfter', () {
    final stops = [
      stopAt('a', north: 0.01),
      stopAt('b', east: 0.01),
      stopAt('c', north: 0.02),
    ];

    test('is the first stop when nothing has been visited', () {
      expect(
        planOver(stops, ['a', 'b', 'c']).nextStopAfter(const {}),
        stops[0].id,
      );
    });

    test('skips what has been visited, in sequence order', () {
      final plan = planOver(stops, ['a', 'b', 'c']);

      expect(plan.nextStopAfter({stops[0].id}), stops[1].id);
      expect(plan.nextStopAfter({stops[0].id, stops[1].id}), stops[2].id);
    });

    test('is null when the route is finished', () {
      final plan = planOver(stops, ['a', 'b', 'c']);

      expect(plan.nextStopAfter(stops.map((s) => s.id).toSet()), isNull);
    });

    test('follows the sequence rather than the order stops were given', () {
      final plan = planOver(stops, ['c', 'b', 'a']);

      expect(plan.nextStopAfter(const {}), stops[2].id);
    });
  });

  group('hasDeviated', () {
    final stops = [stopAt('a', north: 0.05), stopAt('b', north: 0.06)];

    test('a courier heading for the first stop has not deviated', () {
      final plan = planOver(stops, ['a', 'b']);

      final deviated = plan.hasDeviated(
        position: near(north: 0.02),
        nextStop: stops[0].id,
        toleranceMetres: 500,
      );

      expect(unwrap(deviated), isFalse);
    });

    test('a courier in the wrong district has', () {
      final plan = planOver(stops, ['a', 'b']);

      final deviated = plan.hasDeviated(
        position: near(north: -0.2),
        nextStop: stops[0].id,
        toleranceMetres: 500,
      );

      expect(unwrap(deviated), isTrue);
    });

    test('measures the second leg from the first stop, not from the depot', () {
      // The mistake this catches: judging every leg against the origin would
      // report a deviation for a courier who is correctly halfway across the
      // route.
      final plan = planOver(stops, ['a', 'b']);

      final deviated = plan.hasDeviated(
        position: near(north: 0.055),
        nextStop: stops[1].id,
        toleranceMetres: 200,
      );

      expect(unwrap(deviated), isFalse);
    });

    test('the tolerance absorbs the difference between a line and a road', () {
      // Due east of the depot, while the route runs due north: further from
      // the first stop than the leg to it is long, so only a generous
      // tolerance forgives it.
      final plan = planOver(stops, ['a', 'b']);
      final position = near(east: 0.05);

      expect(
        unwrap(
          plan.hasDeviated(
            position: position,
            nextStop: stops[0].id,
            toleranceMetres: 5000,
          ),
        ),
        isFalse,
      );
      expect(
        unwrap(
          plan.hasDeviated(
            position: position,
            nextStop: stops[0].id,
            toleranceMetres: 0,
          ),
        ),
        isTrue,
      );
    });

    test('reports a stop that is not on the route', () {
      final plan = planOver(stops, ['a', 'b']);
      final stranger = stopAt('z', east: 0.5);

      expect(
        plan
            .hasDeviated(
              position: depot,
              nextStop: stranger.id,
              toleranceMetres: 500,
            )
            .isFailure,
        isTrue,
      );
    });
  });
}
