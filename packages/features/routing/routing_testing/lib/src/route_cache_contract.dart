import 'package:routing_api/routing_api.dart';
import 'package:test/test.dart';

import 'route_fixtures.dart';

/// The behaviour every `RouteCache` has to have.
///
/// Run against `InMemoryRouteCache` here and against the key-value backed
/// adapter in `routing_infrastructure`. Smaller than the optimiser kit,
/// because the port is smaller — but the two assertions in it are the ones a
/// courier notices when they are wrong.
///
/// [createCache] must return a fresh, empty cache on every call.
void runRouteCacheContract(RouteCache Function() createCache) {
  group('RouteCache contract', () {
    late RouteCache cache;

    final stops = [
      RouteFixtures.stop('a', north: 0.01),
      RouteFixtures.stop('b', east: 0.02),
    ];

    setUp(() => cache = createCache());

    test('reads back the plan that was written', () async {
      final plan = RouteFixtures.plan(stops, ['a', 'b']);

      expect((await cache.write(plan)).isSuccess, isTrue);
      final read = await cache.read(plan.courier);

      expect(read.fold((p) => p.id, (f) => throw StateError('$f')), plan.id);
    });

    test('reads back the order, not just the stops', () async {
      // The assertion that catches an implementation which stores the stops
      // and rebuilds an order from them. A courier restarting the app in a
      // basement has to get the route they were driving, not an arbitrary
      // permutation of the same parcels.
      final plan = RouteFixtures.plan(stops, ['b', 'a']);
      await cache.write(plan);

      final read = await cache.read(plan.courier);
      final stored = read.fold((p) => p, (f) => throw StateError('$f'));

      expect(stored.sequence.order, plan.sequence.order);
    });

    test('reads back the estimates', () async {
      final plan = RouteFixtures.plan(stops, ['a', 'b']);
      await cache.write(plan);

      final read = await cache.read(plan.courier);
      final stored = read.fold((p) => p, (f) => throw StateError('$f'));

      expect(
        stored.etaFor(stops.first.id)?.arrivesAt,
        plan.etaFor(stops.first.id)?.arrivesAt,
      );
    });

    test('reports a courier with no plan', () async {
      final read = await cache.read(RouteFixtures.courier('nobody'));

      expect(read.fold((_) => null, (f) => f), isA<NoPlan>());
    });

    test('keeps one plan per courier, replacing the last', () async {
      final first = RouteFixtures.plan(stops, ['a', 'b']);
      final second = RouteFixtures.plan(stops, ['b', 'a'], id: 'plan-2');

      await cache.write(first);
      await cache.write(second);

      final read = await cache.read(first.courier);
      expect(
        read.fold((p) => p.id.value, (f) => throw StateError('$f')),
        'plan-2',
      );
    });

    test('keeps different couriers apart', () async {
      final mine = RouteFixtures.plan(stops, ['a', 'b']);
      await cache.write(mine);

      final theirs = await cache.read(RouteFixtures.courier('courier-2'));

      expect(theirs.isFailure, isTrue);
    });

    test('clearing removes the plan', () async {
      final plan = RouteFixtures.plan(stops, ['a', 'b']);
      await cache.write(plan);

      expect((await cache.clear(plan.courier)).isSuccess, isTrue);
      expect((await cache.read(plan.courier)).isFailure, isTrue);
    });

    test('clearing what is not there succeeds', () async {
      // A sign-out that ran twice is not an error, and an implementation that
      // made it one would leave a screen reporting a failure for work that is
      // already done.
      expect(
        (await cache.clear(RouteFixtures.courier('nobody'))).isSuccess,
        isTrue,
      );
    });

    test('the port never throws', () async {
      // Invariant 1.2.9.
      expect(
        (await cache.read(RouteFixtures.courier('nobody'))).isFailure,
        isTrue,
      );
      expect(
        (await cache.clear(RouteFixtures.courier('nobody'))).isSuccess,
        isTrue,
      );
    });
  });
}
