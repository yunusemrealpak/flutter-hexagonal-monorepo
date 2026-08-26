@Tags(['unit'])
library;

import 'package:core_ports/core_ports.dart';
import 'package:routing_api/routing_api.dart';
import 'package:routing_testing/routing_testing.dart';
import 'package:test/test.dart';

import 'support/harness.dart';

void main() {
  late Harness harness;

  final stops = [
    RouteFixtures.stop('a', north: 0.01),
    RouteFixtures.stop('b', east: 0.02),
  ];

  setUp(() => harness = Harness());
  tearDown(() => harness.dispose());

  group('PlanRoute', () {
    test('produces a plan over the stops it was given', () async {
      final plan = unwrap(await harness.plan(stops));

      expect(plan.sequence.length, 2);
      expect(plan.courier, RouteFixtures.courier());
    });

    test('takes the departure instant from the clock', () async {
      // Rule A1. A route whose start time came from DateTime.now() is a route
      // whose estimates nobody can assert on.
      final plan = unwrap(await harness.plan(stops));

      expect(plan.departAt, RouteFixtures.noon);
    });

    test('takes the identifier from the port', () async {
      // Rule A3, and it earns its keep here: plans are replaced rather than
      // mutated, so "is this a new plan?" is a question about identifiers.
      final plan = unwrap(await harness.plan(stops));

      expect(plan.id.value, 'plan-1');
    });

    test('caches the plan it produced', () async {
      final plan = unwrap(await harness.plan(stops));

      final cached = unwrap(await harness.cache.read(plan.courier));
      expect(cached.id, plan.id);
    });

    test('fetches the traffic profile and hands it to the optimiser', () async {
      // The architectural point of this use case. A remote solver could fetch
      // its own profile and a device-side heuristic could not, so a port whose
      // implementations saw different inputs would have no writable contract.
      final busy = unwrap(TrafficProfile.of(freeFlowKmh: 20, congestion: 2));
      harness.traffic.reports(busy);

      final plan = unwrap(await harness.plan(stops));

      expect(harness.optimizer.requests.single.traffic, busy);
      expect(plan.traffic, busy);
    });

    test('asks the traffic service about the departure instant', () async {
      // The port takes `at` rather than reading a clock: a dispatcher planning
      // tomorrow morning's routes at five in the afternoon wants tomorrow
      // morning's traffic.
      await harness.plan(stops);

      expect(harness.traffic.askedAbout, [RouteFixtures.noon]);
    });

    test(
      'plans against assumed traffic when the service is unreachable',
      () async {
        // An ordering is what a courier in a tunnel actually needs, and it is
        // still correct when the times attached to it are guesses.
        harness.traffic.failsWith(const RoutingUnavailable(detail: 'offline'));

        final plan = unwrap(await harness.plan(stops));

        expect(plan.traffic, TrafficProfile.assumed);
        expect(harness.logger.recordsAt(LogLevel.debug), isNotEmpty);
      },
    );

    test('reports an optimiser that could not answer', () async {
      harness.optimizer.failNextWith(
        const RoutingUnavailable(detail: 'no solver'),
      );

      expect((await harness.plan(stops)).isFailure, isTrue);
    });

    test('reports a stop it cannot place, rather than guessing', () async {
      final result = await harness.plan([
        stops.first,
        RouteFixtures.ungeocoded('x'),
      ]);

      expect(result.fold((_) => null, (f) => f), isA<StopNotGeocoded>());
    });

    test(
      'still returns the plan when the cache could not be written',
      () async {
        // A courier who has been given a route has been given a route. The cost
        // of a failed write is a restart that has to ask again, which is much
        // better than an error where a stop list should be.
        harness.cache.failNextWith(
          const RoutingUnavailable(detail: 'full disk'),
        );

        final result = await harness.plan(stops);

        expect(result.isSuccess, isTrue);
        expect(harness.logger.recordsAt(LogLevel.warning), hasLength(1));
      },
    );

    test('an empty route is a plan, not a failure', () async {
      final plan = unwrap(await harness.plan(const []));

      expect(plan.sequence.isEmpty, isTrue);
      expect(plan.finishesAt, RouteFixtures.noon);
    });
  });

  group('constraints', () {
    test('passes them through to the optimiser', () async {
      final constraints = [RouteConstraint.mustEndAt(stops.last.id)];

      await harness.plan(stops, constraints: constraints);

      expect(harness.optimizer.requests.single.constraints, constraints);
    });

    test('reports an unsatisfiable one from the optimiser', () async {
      final result = await harness.plan(
        stops,
        constraints: const [RouteConstraint.maxStops(1)],
      );

      expect(
        result.fold((_) => null, (f) => f),
        isA<ConstraintUnsatisfiable>(),
      );
    });

    test(
      'checks maxDuration against the plan, not against the request',
      () async {
        // The duration follows from the order, and the order is what an
        // optimiser is being asked for. Checking the limit before there is a
        // plan would mean checking it against a route nobody has chosen yet.
        final result = await harness.plan(
          stops,
          constraints: const [
            RouteConstraint.maxDuration(Duration(minutes: 1)),
          ],
        );

        final failure = result.fold((_) => null, (f) => f);
        expect(failure, isA<ConstraintUnsatisfiable>());
        expect('$failure', contains('maxDuration'));
      },
    );

    test('accepts a maxDuration the route fits inside', () async {
      final result = await harness.plan(
        stops,
        constraints: const [RouteConstraint.maxDuration(Duration(hours: 4))],
      );

      expect(result.isSuccess, isTrue);
    });
  });
}
