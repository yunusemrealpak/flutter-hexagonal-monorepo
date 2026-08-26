@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:core_testing/core_testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_dio/http_dio.dart';
import 'package:location_service/location_service.dart';
import 'package:routing_api/routing_api.dart';
import 'package:routing_infrastructure/routing_infrastructure.dart';
import 'package:routing_testing/routing_testing.dart';

void main() {
  final stops = [
    RouteFixtures.stop('a', north: 0.01),
    RouteFixtures.stop('b', east: 0.02),
  ];

  group('RemoteSolverOptimizer', () {
    late FakeHttpTransport http;
    late RemoteSolverOptimizer optimizer;

    setUp(() {
      http = FakeHttpTransport();
      optimizer = RemoteSolverOptimizer(transport: http);
    });

    test('sends the stops, the origin and the profile', () async {
      http.enqueueJson(<String, dynamic>{
        'order': [stops[0].id.value, stops[1].id.value],
      });

      await optimizer.optimise(RouteFixtures.request(stops));

      final body = http.lastRequest!.body! as Map<String, dynamic>;
      expect(http.lastRequest!.method, HttpMethod.post);
      expect(body['originLatitude'], RouteFixtures.depot.latitude);
      expect(body['freeFlowKmh'], TrafficProfile.assumed.freeFlowKmh);
      expect(body['stops'] as List<dynamic>, hasLength(2));
      expect(body['departAt'], endsWith('Z'));
    });

    test('sends the anchors it was given', () async {
      http.enqueueJson(<String, dynamic>{
        'order': [stops[1].id.value, stops[0].id.value],
      });

      await optimizer.optimise(
        RouteFixtures.request(
          stops,
          constraints: [RouteConstraint.mustStartAt(stops[1].id)],
        ),
      );

      final body = http.lastRequest!.body! as Map<String, dynamic>;
      expect(body['mustStartAt'], stops[1].id.value);
    });

    test(
      'validates before it asks, and an impossible request never leaves',
      () async {
        // The obvious reason is not to spend a request on a question with no
        // answer. The load-bearing one is that a port's contract cannot be
        // delegated to somebody else's server.
        final refused = await optimizer.optimise(
          RouteFixtures.request(
            stops,
            constraints: const [RouteConstraint.maxStops(1)],
          ),
        );

        expect(
          refused.fold((_) => null, (f) => f),
          isA<ConstraintUnsatisfiable>(),
        );
        expect(http.requests, isEmpty);
      },
    );

    test('does not ask a solver to order nothing', () async {
      final answer = await optimizer.optimise(RouteFixtures.request(const []));

      expect(answer.isSuccess, isTrue);
      expect(http.requests, isEmpty);
    });

    test('corrects a solver that ignored an anchor', () async {
      // A solver run by another team is free to do as it likes. An adapter is
      // responsible for the contract it implements, whoever is behind it.
      http.enqueueJson(<String, dynamic>{
        'order': [stops[0].id.value, stops[1].id.value],
      });

      final answer = await optimizer.optimise(
        RouteFixtures.request(
          stops,
          constraints: [RouteConstraint.mustStartAt(stops[1].id)],
        ),
      );

      expect(
        answer.fold((s) => s.first, (f) => throw StateError('$f')),
        stops[1].id,
      );
    });

    test('refuses a solver that dropped a stop', () async {
      // Rather than returning a route with a missing parcel.
      http.enqueueJson(<String, dynamic>{
        'order': [stops[0].id.value],
      });

      final answer = await optimizer.optimise(RouteFixtures.request(stops));

      expect(answer.fold((_) => null, (f) => f), isA<SequenceDoesNotMatch>());
    });

    test('refuses a solver that invented a stop', () async {
      http.enqueueJson(<String, dynamic>{
        'order': [stops[0].id.value, stops[1].id.value, 'stranger'],
      });

      expect(
        (await optimizer.optimise(RouteFixtures.request(stops))).isFailure,
        isTrue,
      );
    });

    test('reports a body it cannot read', () async {
      http.enqueueJson('not an object');

      expect(
        (await optimizer.optimise(RouteFixtures.request(stops))).isFailure,
        isTrue,
      );
    });

    test('turns every transport failure into RoutingUnavailable', () async {
      // Unlike sync's transport, this port's caller has exactly one response
      // to all of them — plan without a solver — so distinguishing a 503 from
      // a timeout here would be inventing cases nobody branches on.
      final failures = <TransportFailure>[
        const TransportOffline(),
        const TransportTimeout(TransportTimeoutPhase.receive),
        const TransportRejected(HttpResponse(statusCode: 503)),
        const TransportCancelled(),
        const TransportCertificateRejected(),
        const TransportUnexpected(detail: 'something'),
      ];

      for (final failure in failures) {
        http.enqueueFailure(failure);
        final answer = await optimizer.optimise(RouteFixtures.request(stops));
        expect(answer.fold((_) => null, (f) => f), isA<RoutingUnavailable>());
      }
    });
  });

  group('RestTrafficData', () {
    late FakeHttpTransport http;
    late RestTrafficData traffic;

    setUp(() {
      http = FakeHttpTransport();
      traffic = RestTrafficData(transport: http);
    });

    test('asks about the instant it was given, not about now', () async {
      final tomorrow = RouteFixtures.noon.add(const Duration(days: 1));
      http.enqueueJson(<String, dynamic>{
        'freeFlowKmh': 40.0,
        'congestion': 1.5,
      });

      await traffic.around(RouteFixtures.depot, at: tomorrow);

      expect(
        http.lastRequest!.query['at'],
        tomorrow.toUtc().toIso8601String(),
      );
    });

    test('reads the profile back', () async {
      http.enqueueJson(<String, dynamic>{
        'freeFlowKmh': 40.0,
        'congestion': 1.5,
      });

      final profile = await traffic.around(
        RouteFixtures.depot,
        at: RouteFixtures.noon,
      );

      final read = profile.fold((p) => p, (f) => throw StateError('$f'));
      expect(read.freeFlowKmh, 40.0);
      expect(read.congestion, 1.5);
    });

    test('falls back to the assumed profile for a half-sent answer', () async {
      // A traffic service answering with half a profile is having a bad day.
      // Refusing to plan over it would leave a courier with no route over a
      // number that was going to be approximate anyway.
      http.enqueueJson(<String, dynamic>{'freeFlowKmh': 40.0});

      final profile = await traffic.around(
        RouteFixtures.depot,
        at: RouteFixtures.noon,
      );

      expect(
        profile.fold((p) => p.congestion, (f) => throw StateError('$f')),
        TrafficProfile.assumed.congestion,
      );
    });

    test(
      'refuses a congestion multiplier the domain will not accept',
      () async {
        http.enqueueJson(<String, dynamic>{
          'freeFlowKmh': 40.0,
          'congestion': 0.2,
        });

        expect(
          (await traffic.around(
            RouteFixtures.depot,
            at: RouteFixtures.noon,
          )).isFailure,
          isTrue,
        );
      },
    );
  });

  group('KeyValueRouteCache', () {
    test('stores a plan under a namespaced key', () async {
      final store = InMemoryKeyValueStore();
      final cache = KeyValueRouteCache(store: store);
      final plan = RouteFixtures.plan(stops, ['a', 'b']);

      await cache.write(plan);

      expect(
        store.entries.keys.single,
        '${KeyValueRouteCache.keyPrefix}${plan.courier.value}',
      );
    });

    test('recomputes the estimates rather than storing them', () async {
      // The DTO carries the order, the departure, the traffic and the service
      // times — everything the estimates are derived from — and no arrival
      // instants. Persisting those would put a second source of truth on the
      // device.
      final store = InMemoryKeyValueStore();
      final cache = KeyValueRouteCache(store: store);
      final plan = RouteFixtures.plan(stops, ['a', 'b']);

      await cache.write(plan);
      final stored = store.entries.values.single;

      expect(stored, isNot(contains('arrivesAt')));
      final read = await cache.read(plan.courier.value);
      expect(
        read.fold((p) => p.etaFor(stops.first.id)!.arrivesAt, (f) => null),
        plan.etaFor(stops.first.id)!.arrivesAt,
      );
    });

    test('reports a stored blob that is no longer JSON', () async {
      // A half-written file, or a downgrade. Not something a use case can
      // handle as an exception, and invariant 1.2.9 forbids it crossing as
      // one.
      final store = InMemoryKeyValueStore();
      final cache = KeyValueRouteCache(store: store);
      final courier = RouteFixtures.courier();
      await store.write(
        '${KeyValueRouteCache.keyPrefix}${courier.value}',
        'not json at all',
      );

      final read = await cache.read(courier.value);

      expect(read.fold((_) => null, (f) => f), isA<MalformedRouteValue>());
    });

    test('separates a corrupt plan from an unreachable store', () async {
      // The two lead somewhere different: one means "ask again later" and the
      // other means "this plan is gone, replan". A courier waiting for a cache
      // that will never answer is the cost of collapsing them.
      final store = InMemoryKeyValueStore()
        ..failNextWith(const StoreCorrupted('routing.plan.courier-1'));
      final cache = KeyValueRouteCache(store: store);

      final corrupt = await cache.read(RouteFixtures.courier().value);
      expect(corrupt.fold((_) => null, (f) => f), isA<MalformedRouteValue>());

      store.failNextWith(const StoreUnavailable(detail: 'locked'));
      final unavailable = await cache.read(RouteFixtures.courier().value);
      expect(
        unavailable.fold((_) => null, (f) => f),
        isA<RoutingUnavailable>(),
      );
    });
  });

  group('DeviceLocationStream', () {
    GeoFix fixAt({double accuracy = 10}) => GeoFix(
      latitude: RouteFixtures.depot.latitude,
      longitude: RouteFixtures.depot.longitude,
      accuracyMetres: accuracy,
      capturedAt: RouteFixtures.noon,
    );

    test('turns a fix into a place', () async {
      final source = FakeLocationSource()..queue(Success(fixAt()));
      final stream = DeviceLocationStream(source: source);

      final at = await stream.current();

      expect(
        at.fold((p) => p, (f) => throw StateError('$f')),
        RouteFixtures.depot,
      );
    });

    test('refuses a fix too vague to be a position', () async {
      // "You are somewhere over there" is not a position. Forwarding it would
      // have the deviation check report a wrong turn for a courier sitting
      // still.
      final source = FakeLocationSource()
        ..queue(Success(fixAt(accuracy: 2000)));
      final stream = DeviceLocationStream(source: source);

      final at = await stream.current();

      expect(at.fold((_) => null, (f) => f), isA<PositionUnavailable>());
    });

    test('turns every location failure into PositionUnavailable', () async {
      // location_service distinguishes five cases because a permission screen
      // behaves differently about each. Routing has one response to all of
      // them, so the narrowing is deliberate rather than lossy.
      final failures = <LocationFailure>[
        const LocationServicesDisabled(),
        const LocationPermissionDenied(),
        const LocationPermissionBlocked(),
        const LocationTimeout(Duration(seconds: 10)),
        const LocationUnavailable(detail: 'the platform said no'),
      ];

      for (final failure in failures) {
        final source = FakeLocationSource()..queue(Failed(failure));
        final stream = DeviceLocationStream(source: source);

        final at = await stream.current();
        expect(at.fold((_) => null, (f) => f), isA<PositionUnavailable>());
      }
    });
  });
}
