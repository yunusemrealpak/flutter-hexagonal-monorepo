@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:routing_api/routing_api.dart';
import 'package:routing_infrastructure/routing_infrastructure.dart';
import 'package:routing_testing/routing_testing.dart';

void main() {
  const optimizer = LocalHeuristicOptimizer();

  Future<List<String>> order(
    List<Stop> stops, {
    List<RouteConstraint> constraints = const [],
  }) async {
    final sequence = await optimizer.optimise(
      RouteFixtures.request(stops, constraints: constraints),
    );
    return sequence.fold(
      (value) => [for (final id in value.order) id.value],
      (failure) => throw StateError('$failure'),
    );
  }

  double lengthOf(List<Stop> stops, List<String> route) {
    final byId = {for (final stop in stops) stop.id.value: stop};
    var total = 0.0;
    var from = RouteFixtures.depot;
    for (final id in route) {
      final to = byId[id]!.at;
      total += from.distanceTo(to);
      from = to;
    }
    return total;
  }

  group('the quality this implementation promises', () {
    // The contract kit asserts validity and says nothing about which
    // permutation, because "a shorter route" is the axis the implementations
    // are meant to differ on. These are the assertions that belong here
    // instead: what *this* optimiser claims about the routes it produces.

    test('visits a chain of stops in order rather than zig-zagging', () async {
      // Four stops in a line going north, handed over shuffled. A route that
      // did not sort them would drive the district twice.
      final stops = [
        RouteFixtures.stop('c', north: 0.03),
        RouteFixtures.stop('a', north: 0.01),
        RouteFixtures.stop('d', north: 0.04),
        RouteFixtures.stop('b', north: 0.02),
      ];

      expect(await order(stops), ['a', 'b', 'c', 'd']);
    });

    test(
      'beats the order it was given on a route with a detour in it',
      () async {
        // The input alternates between two clusters; the answer must not.
        final stops = [
          RouteFixtures.stop('near-1', north: 0.005),
          RouteFixtures.stop('far-1', north: 0.05),
          RouteFixtures.stop('near-2', north: 0.008, east: 0.002),
          RouteFixtures.stop('far-2', north: 0.052, east: 0.002),
        ];
        final asGiven = [for (final stop in stops) stop.id.value];

        final answer = await order(stops);

        expect(lengthOf(stops, answer), lessThan(lengthOf(stops, asGiven)));
      },
    );

    test(
      '2-opt removes the crossing nearest neighbour leaves behind',
      () async {
        // The classic greedy failure: the walk takes the two close stops first
        // and then has to come back for the one it passed. With the improvement
        // pass off, the route is longer.
        const greedyOnly = LocalHeuristicOptimizer(improvementPasses: 0);
        final stops = [
          RouteFixtures.stop('a', east: 0.01),
          RouteFixtures.stop('b', east: 0.02, north: 0.001),
          RouteFixtures.stop('c', east: 0.005, north: 0.03),
          RouteFixtures.stop('d', east: 0.021, north: 0.031),
        ];

        final improved = await order(stops);
        final greedy = (await greedyOnly.optimise(RouteFixtures.request(stops)))
            .fold(
              (value) => [for (final id in value.order) id.value],
              (failure) => throw StateError('$failure'),
            );

        expect(
          lengthOf(stops, improved),
          lessThanOrEqualTo(lengthOf(stops, greedy)),
        );
      },
    );

    test('is deterministic across identical requests', () async {
      // Not an optimisation property — a reproducibility one. An optimiser
      // that reordered a route every time a screen refreshed would move a
      // courier's next stop while they were reading it.
      final stops = [
        RouteFixtures.stop('a', north: 0.01),
        RouteFixtures.stop('b', east: 0.01),
        RouteFixtures.stop('c', north: 0.02, east: 0.02),
      ];

      expect(await order(stops), await order(stops));
    });

    test('breaks a tie on the identifier rather than on map order', () async {
      // Two stops the same distance away. Without the tie-break the answer
      // depends on how a Map happened to iterate, which is stable until it is
      // not.
      final stops = [
        RouteFixtures.stop('b', north: 0.01),
        RouteFixtures.stop('a', north: -0.01),
      ];

      expect((await order(stops)).first, 'a');
    });
  });

  group('anchors are applied to the improved order', () {
    test('a required start moves to the front without losing a stop', () async {
      final stops = [
        RouteFixtures.stop('a', north: 0.01),
        RouteFixtures.stop('b', north: 0.02),
        RouteFixtures.stop('far', north: 0.09),
      ];

      final answer = await order(
        stops,
        constraints: [RouteConstraint.mustStartAt(stops.last.id)],
      );

      expect(answer.first, 'far');
      expect(answer, hasLength(3));
    });
  });

  group('it needs nothing stood up', () {
    test('no clock, no randomness, no network', () async {
      // The reason this adapter is the cheapest thing in the workspace to
      // test: it is pure computation, so the test above constructs it with a
      // const constructor and nothing else.
      final answer = await order([RouteFixtures.stop('a', north: 0.01)]);

      expect(answer, ['a']);
    });
  });
}
