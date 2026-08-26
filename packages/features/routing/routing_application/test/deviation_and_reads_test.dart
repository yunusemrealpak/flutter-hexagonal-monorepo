@Tags(['unit'])
library;

import 'package:core_ports/core_ports.dart';
import 'package:routing_api/routing_api.dart';
import 'package:routing_testing/routing_testing.dart';
import 'package:test/test.dart';

import 'support/harness.dart';

void main() {
  late Harness harness;

  // A route that runs due north: the depot, then a kilometre out, then five.
  final stops = [
    RouteFixtures.stop('near', north: 0.01),
    RouteFixtures.stop('far', north: 0.05),
  ];

  final courier = RouteFixtures.courier();

  setUp(() => harness = Harness());
  tearDown(() => harness.dispose());

  group('NextStop', () {
    test('is the first stop when nothing has been visited', () async {
      await harness.plan(stops);

      final next = unwrap(
        await harness.nextStop((courier: courier, visited: const {})),
      );

      expect(next, stops.first.id);
    });

    test('skips what has been visited', () async {
      await harness.plan(stops);

      final next = unwrap(
        await harness.nextStop((courier: courier, visited: {stops.first.id})),
      );

      expect(next, stops.last.id);
    });

    test('a finished route is a success with nothing in it', () async {
      // An empty afternoon is something a courier earns, not an error.
      await harness.plan(stops);

      final next = unwrap(
        await harness.nextStop((
          courier: courier,
          visited: stops.map((s) => s.id).toSet(),
        )),
      );

      expect(next, isNull);
    });

    test('reports a courier with no plan', () async {
      final next = await harness.nextStop((
        courier: courier,
        visited: const {},
      ));

      expect(next.fold((_) => null, (f) => f), isA<NoPlan>());
    });
  });

  group('Resequence', () {
    test('reorders the cached plan and stores the result', () async {
      // Stored, and the failure reported — unlike PlanRoute. A dispatcher told
      // the reorder worked has to be able to rely on the courier seeing it.
      await harness.plan(stops);

      final moved = unwrap(
        await harness.resequence((
          courier: courier,
          order: [stops.last.id, stops.first.id],
        )),
      );

      expect(moved.sequence.first, stops.last.id);
      final cached = unwrap(await harness.cache.read(courier.value));
      expect(cached.sequence.first, stops.last.id);
    });

    test('recomputes the estimates', () async {
      final before = unwrap(await harness.plan(stops));

      final after = unwrap(
        await harness.resequence((
          courier: courier,
          order: [stops.last.id, stops.first.id],
        )),
      );

      expect(after.finishesAt, isNot(before.finishesAt));
    });

    test('refuses an order that drops a stop', () async {
      await harness.plan(stops);

      final moved = await harness.resequence((
        courier: courier,
        order: [stops.first.id],
      ));

      expect(moved.fold((_) => null, (f) => f), isA<SequenceDoesNotMatch>());
    });

    test('reports a cache that could not be written', () async {
      await harness.plan(stops);
      harness.cache.failNextWith(const RoutingUnavailable());

      final moved = await harness.resequence((
        courier: courier,
        order: [stops.last.id, stops.first.id],
      ));

      expect(moved.isFailure, isTrue);
    });
  });

  group('RecalculateOnDeviation', () {
    test('leaves the plan alone when the courier is on route', () async {
      final planned = unwrap(await harness.plan(stops));
      harness.location.moveTo(RouteFixtures.near(north: 0.005));

      final after = unwrap(
        await harness.recalculate((courier: courier, visited: const {})),
      );

      expect(after.id, planned.id);
    });

    test('replans when the courier is in the wrong district', () async {
      final planned = unwrap(await harness.plan(stops));
      harness.location.moveTo(RouteFixtures.near(north: -0.2));

      final after = unwrap(
        await harness.recalculate((courier: courier, visited: const {})),
      );

      // A new identifier is how a caller tells a recalculation from a
      // no-change — which is the reason plans are replaced rather than
      // mutated.
      expect(after.id, isNot(planned.id));
      expect(harness.logger.recordsAt(LogLevel.info), isNotEmpty);
    });

    test('replans from where the courier actually is', () async {
      await harness.plan(stops);
      final wrongWay = RouteFixtures.near(north: -0.2);
      harness.location.moveTo(wrongWay);

      final after = unwrap(
        await harness.recalculate((courier: courier, visited: const {})),
      );

      expect(after.origin, wrongWay);
    });

    test('drops the stops already visited', () async {
      // The difference between a recalculation and a fresh morning.
      await harness.plan(stops);
      harness.location.moveTo(RouteFixtures.near(north: -0.2));

      final after = unwrap(
        await harness.recalculate((
          courier: courier,
          visited: {stops.first.id},
        )),
      );

      expect(after.stops.map((s) => s.id), [stops.last.id]);
    });

    test('does not replan when the position is unknown', () async {
      // A courier in a car park with no fix has not deviated; they are
      // invisible. Replanning on no evidence would reorder a route because
      // somebody walked into a basement.
      final planned = unwrap(await harness.plan(stops));
      harness.location.failsWith(const PositionUnavailable(detail: 'no fix'));

      final after = unwrap(
        await harness.recalculate((courier: courier, visited: const {})),
      );

      expect(after.id, planned.id);
      expect(harness.optimizer.requests, hasLength(1));
    });

    test('does nothing on a finished route', () async {
      final planned = unwrap(await harness.plan(stops));
      harness.location.moveTo(RouteFixtures.near(north: -0.2));

      final after = unwrap(
        await harness.recalculate((
          courier: courier,
          visited: stops.map((s) => s.id).toSet(),
        )),
      );

      expect(after.id, planned.id);
    });

    test('reports a courier with no plan', () async {
      final after = await harness.recalculate((
        courier: courier,
        visited: const {},
      ));

      expect(after.fold((_) => null, (f) => f), isA<NoPlan>());
    });

    test('a tighter tolerance replans sooner', () async {
      // The tolerance absorbs the difference between a great-circle distance
      // and a road. Making it a constructor argument is what lets an app tune
      // the trade rather than inheriting a literal.
      final strict = Harness(toleranceMetres: 1);
      addTearDown(strict.dispose);
      final planned = unwrap(await strict.plan(stops));
      strict.location.moveTo(RouteFixtures.near(east: 0.03));

      final after = unwrap(
        await strict.recalculate((courier: courier, visited: const {})),
      );

      expect(after.id, isNot(planned.id));
    });
  });

  group('RoutingCoordinator', () {
    test('emits a plan whenever one is produced', () async {
      final seen = <RoutePlan>[];
      final subscription = harness.coordinator.changes().listen(seen.add);

      await harness.coordinator.planRoute(
        courier: courier,
        origin: RouteFixtures.depot,
        stops: stops,
      );
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(seen, hasLength(1));
    });

    test('emits nothing for a refused plan', () async {
      // The route did not change, and a screen that redrew on it would flicker
      // for no reason.
      final seen = <RoutePlan>[];
      final subscription = harness.coordinator.changes().listen(seen.add);

      await harness.coordinator.resequence(courier: courier, order: const []);
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(seen, isEmpty);
    });

    test('adds no rule of its own', () async {
      await harness.coordinator.planRoute(
        courier: courier,
        origin: RouteFixtures.depot,
        stops: stops,
      );

      final next = await harness.coordinator.nextStop(
        courier: courier,
        visited: const {},
      );

      expect(unwrap(next), stops.first.id);
    });
  });
}
