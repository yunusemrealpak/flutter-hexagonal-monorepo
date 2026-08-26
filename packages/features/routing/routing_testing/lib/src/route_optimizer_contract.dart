import 'package:routing_api/routing_api.dart';
import 'package:test/test.dart';

import 'route_fixtures.dart';

/// The behaviour every `RouteOptimizerPort` has to have, whatever is behind it.
///
/// This is the contract kit scenario 4 turns on. Three implementations run it:
///
/// ```dart
/// void main() {
///   runRouteOptimizerContract(LocalHeuristicOptimizer.new);   // on the device
///   runRouteOptimizerContract(() => RemoteSolverOptimizer(…)); // on a server
///   runRouteOptimizerContract(FakeRouteOptimizer.new);         // in a test
/// }
/// ```
///
/// **What it asserts, and what it deliberately does not.** It asserts that
/// every answer is a *valid permutation* of the request under its constraints
/// — every stop once, nothing invented, anchors honoured, impossible requests
/// refused. It says nothing about which permutation, because "a shorter route"
/// is exactly the axis the two implementations are meant to differ on. A kit
/// that pinned the ordering would fail the moment the remote solver got
/// better, which is the moment it was supposed to be earning its keep.
///
/// Quality is asserted where quality belongs: in each implementation's own
/// tests, against its own promises. `LocalHeuristicOptimizer` claims to beat
/// the input order on a route with an obvious detour in it, and proves that
/// there.
///
/// [createOptimizer] must return a fresh optimiser on every call.
void runRouteOptimizerContract(RouteOptimizerPort Function() createOptimizer) {
  group('RouteOptimizerPort contract', () {
    late RouteOptimizerPort optimizer;

    setUp(() => optimizer = createOptimizer());

    Future<StopSequence> order(OptimisationRequest request) async {
      final result = await optimizer.optimise(request);
      return result.fold(
        (sequence) => sequence,
        (failure) => throw StateError('expected an ordering: $failure'),
      );
    }

    final stops = [
      RouteFixtures.stop('a', north: 0.01),
      RouteFixtures.stop('b', east: 0.02),
      RouteFixtures.stop('c', north: 0.03, east: 0.01),
      RouteFixtures.stop('d', north: -0.02),
    ];

    group('the answer is a permutation', () {
      test('names every stop exactly once', () async {
        // An optimiser that drops a stop drops a parcel, and nobody finds out
        // until the depot counts. This is the first thing the kit checks and
        // the reason it exists.
        final sequence = await order(RouteFixtures.request(stops));

        expect(sequence.length, stops.length);
        expect(
          sequence.order.toSet(),
          stops.map((stop) => stop.id).toSet(),
        );
      });

      test(
        'is accepted by the domain as a sequence over those stops',
        () async {
          // The strongest form of the assertion above: StopSequence.over runs
          // the same three checks the domain runs on a dispatcher's manual
          // reorder, so an optimiser is held to the standard a human is.
          final sequence = await order(RouteFixtures.request(stops));

          expect(StopSequence.over(stops, sequence.order).isSuccess, isTrue);
        },
      );

      test('orders a single stop', () async {
        final one = [stops.first];

        expect((await order(RouteFixtures.request(one))).order, [one.first.id]);
      });

      test('an empty route is an empty answer, not a failure', () async {
        // A courier with no assignments is having an ordinary morning.
        final sequence = await order(RouteFixtures.request(const []));

        expect(sequence.isEmpty, isTrue);
      });

      test('is stable: the same request twice gives the same answer', () async {
        // Not an optimisation property — a *reproducibility* one. An optimiser
        // that reordered a route every time a screen refreshed would move a
        // courier's next stop while they were reading it.
        final request = RouteFixtures.request(stops);

        expect(await order(request), await order(request));
      });
    });

    group('anchors', () {
      test('honours mustStartAt', () async {
        final sequence = await order(
          RouteFixtures.request(
            stops,
            constraints: [RouteConstraint.mustStartAt(stops[2].id)],
          ),
        );

        expect(sequence.first, stops[2].id);
        expect(sequence.length, stops.length);
      });

      test('honours mustEndAt', () async {
        final sequence = await order(
          RouteFixtures.request(
            stops,
            constraints: [RouteConstraint.mustEndAt(stops[1].id)],
          ),
        );

        expect(sequence.order.last, stops[1].id);
      });

      test('honours both at once', () async {
        final sequence = await order(
          RouteFixtures.request(
            stops,
            constraints: [
              RouteConstraint.mustStartAt(stops[3].id),
              RouteConstraint.mustEndAt(stops[0].id),
            ],
          ),
        );

        expect(sequence.first, stops[3].id);
        expect(sequence.order.last, stops[0].id);
        expect(sequence.length, stops.length);
      });
    });

    group('impossible requests are refused, not relaxed', () {
      Future<RoutingFailure> refusal(OptimisationRequest request) async {
        final result = await optimizer.optimise(request);
        return result.fold(
          (sequence) => throw StateError('expected a refusal, got $sequence'),
          (failure) => failure,
        );
      }

      test('a maxStops below the number of stops', () async {
        // An optimiser that truncated to fit would be deciding which two
        // parcels are not delivered today. That is not a decision this layer
        // is entitled to make.
        final failure = await refusal(
          RouteFixtures.request(
            stops,
            constraints: const [RouteConstraint.maxStops(2)],
          ),
        );

        expect(failure, isA<ConstraintUnsatisfiable>());
      });

      test('two different stops named as the start', () async {
        final failure = await refusal(
          RouteFixtures.request(
            stops,
            constraints: [
              RouteConstraint.mustStartAt(stops[0].id),
              RouteConstraint.mustStartAt(stops[1].id),
            ],
          ),
        );

        expect(failure, isA<ConstraintUnsatisfiable>());
      });

      test('an anchor that is not one of the stops', () async {
        final failure = await refusal(
          RouteFixtures.request(
            stops,
            constraints: [
              RouteConstraint.mustStartAt(RouteFixtures.stopId('stranger')),
            ],
          ),
        );

        expect(failure, isA<ConstraintUnsatisfiable>());
      });

      test('a stop that never resolved to a point on the map', () async {
        // Guessing a coordinate would send a courier to the wrong street with
        // full confidence. The honest answer names the stop.
        final failure = await refusal(
          RouteFixtures.request([stops.first, RouteFixtures.ungeocoded('x')]),
        );

        expect(failure, isA<StopNotGeocoded>());
      });
    });

    group('the port never throws', () {
      test('every path out is a Result', () async {
        // Invariant 1.2.9. An implementation that threw would satisfy every
        // assertion above and still break the first caller that relied on the
        // return type telling the whole story.
        expect(
          (await optimizer.optimise(RouteFixtures.request(const []))).isSuccess,
          isTrue,
        );
        expect(
          (await optimizer.optimise(
            RouteFixtures.request([RouteFixtures.ungeocoded('x')]),
          )).isFailure,
          isTrue,
        );
        expect(
          (await optimizer.optimise(
            RouteFixtures.request(
              stops,
              constraints: const [RouteConstraint.maxStops(0)],
            ),
          )).isFailure,
          isTrue,
        );
      });
    });
  });
}
