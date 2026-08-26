@Tags(['unit'])
library;

import 'package:routing_api/routing_api.dart';
import 'package:routing_testing/routing_testing.dart';
import 'package:test/test.dart';

void main() {
  // The fakes run their own contract kits. That is not circular: the kit
  // describes the port, and running it here proves the fake satisfies the
  // description before anything trusts it. `routing_infrastructure` runs the
  // optimiser kit against two more implementations, which is what makes
  // scenario 4 a checked fact rather than a claim.
  runRouteOptimizerContract(FakeRouteOptimizer.new);
  runRouteCacheContract(InMemoryRouteCache.new);

  group('FakeRouteOptimizer', () {
    test('keeps the order it was given', () async {
      // Which is the point of it: a test running against this optimiser is
      // testing the use case, and the order it gets back is the order it put
      // in. A test that needed the heuristic runs against the heuristic.
      final stops = [
        RouteFixtures.stop('a', north: 0.05),
        RouteFixtures.stop('b', north: 0.01),
      ];
      final optimizer = FakeRouteOptimizer();

      final sequence = await optimizer.optimise(RouteFixtures.request(stops));

      expect(
        sequence.fold((s) => s.order, (f) => throw StateError('$f')),
        [stops[0].id, stops[1].id],
      );
    });

    test(
      'answers with a scripted order when a test needs a specific one',
      () async {
        final stops = [
          RouteFixtures.stop('a', north: 0.01),
          RouteFixtures.stop('b', east: 0.01),
        ];
        final optimizer = FakeRouteOptimizer()
          ..answersWith([stops[1].id, stops[0].id]);

        final sequence = await optimizer.optimise(RouteFixtures.request(stops));

        expect(
          sequence.fold((s) => s.order, (f) => throw StateError('$f')),
          [stops[1].id, stops[0].id],
        );
      },
    );

    test(
      'can fail, because a solver that cannot be reached is a real case',
      () async {
        final optimizer = FakeRouteOptimizer()
          ..failNextWith(const RoutingUnavailable(detail: 'no solver'));

        expect(
          (await optimizer.optimise(RouteFixtures.request(const []))).isFailure,
          isTrue,
        );
      },
    );

    test('records what it was asked', () async {
      final optimizer = FakeRouteOptimizer();

      await optimizer.optimise(RouteFixtures.request(const []));

      expect(optimizer.requests, hasLength(1));
    });
  });

  group('FakeTrafficData', () {
    test('records the instant it was asked about', () async {
      // The port takes `at` rather than reading a clock: a dispatcher planning
      // tomorrow morning's routes at five in the afternoon wants tomorrow
      // morning's traffic.
      final traffic = FakeTrafficData();
      final tomorrow = RouteFixtures.noon.add(const Duration(days: 1));

      await traffic.around(RouteFixtures.depot, at: tomorrow);

      expect(traffic.askedAbout, [tomorrow]);
    });

    test('can refuse, which is what happens in a tunnel', () async {
      final traffic = FakeTrafficData()
        ..failsWith(const RoutingUnavailable(detail: 'offline'));

      expect(
        (await traffic.around(
          RouteFixtures.depot,
          at: RouteFixtures.noon,
        )).isFailure,
        isTrue,
      );
    });
  });

  group('FakeLocationStream', () {
    test('has no position until the device gets a fix', () async {
      final stream = FakeLocationStream();
      addTearDown(stream.dispose);

      expect((await stream.current()).isFailure, isTrue);
    });

    test('reports where it was moved to, and tells anyone watching', () async {
      final stream = FakeLocationStream();
      addTearDown(stream.dispose);
      final seen = <GeoPoint>[];
      final subscription = stream.positions().listen(seen.add);

      stream.moveTo(RouteFixtures.near(north: 0.01));
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect((await stream.current()).isSuccess, isTrue);
      expect(seen, hasLength(1));
    });
  });
}
