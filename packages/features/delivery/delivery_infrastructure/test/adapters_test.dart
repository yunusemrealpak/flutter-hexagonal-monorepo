@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:delivery_api/delivery_api.dart';
import 'package:delivery_infrastructure/delivery_infrastructure.dart';
import 'package:delivery_testing/delivery_testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_dio/http_dio.dart';
import 'package:location_service/location_service.dart';

GeoFix _fix({
  double latitude = 40.9900,
  double longitude = 29.0300,
  double accuracyMetres = 8,
}) => GeoFix(
  latitude: latitude,
  longitude: longitude,
  accuracyMetres: accuracyMetres,
  capturedAt: DeliveryFixtures.noon,
);

void main() {
  late FakeHttpTransport transport;
  late FakeLocationSource location;
  late HttpGeoFence fence;

  setUp(() {
    transport = FakeHttpTransport();
    location = FakeLocationSource();
    addTearDown(location.dispose);
    fence = HttpGeoFence(transport: transport, location: location);
  });

  void publishTarget({
    double latitude = 40.9900,
    double longitude = 29.0300,
    double allowedMetres = 100,
  }) => transport.enqueueJson({
    'latitude': latitude,
    'longitude': longitude,
    'allowedMetres': allowedMetres,
  });

  group('HttpGeoFence', () {
    test('puts the courier inside when they are at the address', () async {
      publishTarget();
      location.queue(Success(_fix()));

      final verdict = await fence.locate('SHP-1');

      final answer = verdict.fold((v) => v, (f) => throw StateError('$f'));
      expect(answer.isInside, isTrue);
      expect(answer.metresAway, lessThan(1));
    });

    test('measures the distance when they are not', () async {
      // Roughly a kilometre east, which a hundred-metre fence refuses.
      publishTarget();
      location.queue(Success(_fix(longitude: 29.0420)));

      final answer = (await fence.locate('SHP-1')).fold(
        (v) => v,
        (f) => throw StateError('$f'),
      );

      expect(answer.isInside, isFalse);
      expect(answer.metresAway, greaterThan(500));
    });

    test('takes the radius the operation published', () async {
      // A dense city and a rural round want different numbers, and neither is
      // a fact about this app.
      publishTarget(allowedMetres: 2000);
      location.queue(Success(_fix(longitude: 29.0420)));

      final answer = (await fence.locate('SHP-1')).fold(
        (v) => v,
        (f) => throw StateError('$f'),
      );

      expect(answer.allowedMetres, 2000);
      expect(answer.isInside, isTrue);
    });

    test('refuses a fix too vague to answer the question', () async {
      // A reading with a 400 metre error radius cannot answer a 100 metre
      // fence. Measuring with it anyway would accept a hand-over from the far
      // side of a car park on a day the signal was poor.
      publishTarget();
      location.queue(Success(_fix(accuracyMetres: 400)));

      final refused = await fence.locate('SHP-1');

      expect(
        refused.fold((_) => null, (f) => f),
        isA<DeliveryPositionUnavailable>(),
      );
    });

    test('a device that cannot see itself is position unavailable', () async {
      publishTarget();
      location.queue(
        const Failed(LocationTimeout(Duration(seconds: 8))),
      );

      final refused = await fence.locate('SHP-1');

      expect(
        refused.fold((_) => null, (f) => f),
        isA<DeliveryPositionUnavailable>(),
      );
    });

    test(
      'a target service that cannot be reached is not a position problem',
      () async {
        transport.enqueueFailure(const TransportOffline());

        final refused = await fence.locate('SHP-1');

        expect(refused.fold((_) => null, (f) => f), isA<DeliveryUnavailable>());
      },
    );

    test('an address with no coordinates is a named failure', () async {
      transport.enqueueJson({'allowedMetres': 100.0});

      final refused = await fence.locate('SHP-1');

      expect(
        refused.fold((_) => null, (f) => f),
        isA<MalformedDeliveryValue>(),
      );
    });

    test('asks delivery s own endpoint, never shipments', () async {
      // This package may not depend on a foreign _api at all, so it could not
      // ask shipments where a parcel is going even in principle.
      publishTarget();
      location.queue(Success(_fix()));

      await fence.locate('SHP-1');

      expect(transport.lastRequest!.path, '/delivery/targets/SHP-1');
    });
  });

  group('RestDeliveryGateway', () {
    late RestDeliveryGateway gateway;

    setUp(() => gateway = RestDeliveryGateway(transport: transport));

    test('puts an attempt at its own identifier', () async {
      // The identifier was minted on the device when the courier arrived, and
      // a resend after a lost acknowledgement has to be the same request
      // rather than a second delivery.
      final attempt = DeliveryFixtures.completed();
      transport.enqueueJson(DeliveryMapper.attemptToDto(attempt).toJson());

      await gateway.submit(attempt);

      expect(transport.lastRequest!.method, HttpMethod.put);
      expect(transport.lastRequest!.path, '/delivery/attempts/attempt-1');
    });

    test(
      'reads back the server s copy rather than echoing its input',
      () async {
        // The server is the side that decides what was recorded. A gateway that
        // echoed would hide one that stored something else.
        final sent = DeliveryFixtures.completed();
        final stored = DeliveryMapper.attemptToDto(
          DeliveryFixtures.failed(),
        ).toJson();
        transport.enqueueJson(stored);

        final answer = await gateway.submit(sent);

        expect(
          answer.fold((a) => a.outcome, (f) => throw StateError('$f')),
          isA<AttemptFailed>(),
        );
      },
    );

    test('lists a shipment s visits, oldest first', () async {
      transport.enqueueJson([
        DeliveryMapper.attemptToDto(DeliveryFixtures.failed()).toJson(),
        DeliveryMapper.attemptToDto(
          DeliveryFixtures.completed(id: 'attempt-2'),
        ).toJson(),
      ]);

      final rows = await gateway.attemptsFor('SHP-1');

      expect(rows.fold((r) => r.length, (f) => throw StateError('$f')), 2);
    });

    test('one unreadable row fails the whole read', () async {
      // A gateway that skipped it would answer "one visit" to a question whose
      // true answer is two, and nothing downstream could tell.
      transport.enqueueJson([
        DeliveryMapper.attemptToDto(DeliveryFixtures.failed()).toJson(),
        {'id': ''},
      ]);

      final rows = await gateway.attemptsFor('SHP-1');

      expect(rows.fold((_) => null, (f) => f), isA<DeliveryFailure>());
    });

    test('an unreachable service is delivery unavailable', () async {
      transport.enqueueFailure(const TransportOffline());

      final rows = await gateway.attemptsFor('SHP-1');

      expect(rows.fold((_) => null, (f) => f), isA<DeliveryUnavailable>());
    });
  });

  group('BudgetMediaCompressor', () {
    test('returns a photograph that fits, untouched', () async {
      const compressor = BudgetMediaCompressor();
      final photo = DeliveryFixtures.photo(bytes: const [1, 2]);

      final result = await compressor.compress(photo, limitBytes: 10);

      expect(result.fold((p) => p, (f) => throw StateError('$f')), same(photo));
    });

    test('refuses one that does not, rather than re-encoding it', () async {
      // The decision half of the port, not the arithmetic half. The cheapest
      // place to make a photograph small is the camera; failing here sends the
      // courier back to it rather than leaving an entry stuck in an outbox.
      const compressor = BudgetMediaCompressor();

      final result = await compressor.compress(
        DeliveryFixtures.photo(bytes: const [1, 2, 3, 4]),
        limitBytes: 2,
      );

      final failure = result.fold((_) => null, (f) => f)! as MediaTooLarge;
      expect(failure.bytes, 4);
      expect(failure.limit, 2);
    });
  });
}
