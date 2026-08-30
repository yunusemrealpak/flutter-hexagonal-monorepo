@Tags(['widget'])
library;

import 'package:app_courier/main.dart';
import 'package:core_kernel/core_kernel.dart';
import 'package:delivery_api/delivery_api.dart';
import 'package:delivery_testing/delivery_testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:identity_api/identity_api.dart';
import 'package:shipments_api/shipments_api.dart';

import 'support/test_platform.dart';

void main() {
  const flow = CourierFlow();

  group("the courier's day", () {
    test('a chosen stop leads to its door', () {
      final stop = ShipmentSummary(
        id: 'SHP-1',
        barcode: '4600000000001',
        status: ShipmentStatus.outForDelivery(_actor()),
        consigneeName: 'Ada',
        address: 'Kadıköy',
      );

      final step = flow.fromStop(stop);

      // Field by field rather than as a whole record: two records are equal
      // when their fields are, and a Map is equal only to itself.
      expect(step.route, 'delivery.proof');
      expect(step.parameters, {'shipmentId': 'SHP-1'});
    });

    // Delivery cannot know what a parcel costs — it does not depend on
    // payments and must not — so every settled visit goes to collection and
    // payments answers NothingOwed for the prepaid ones. That is what makes
    // the prepaid case a screen somebody sees.
    test('a hand-over leads to collection, prepaid or not', () {
      final attempt = _handedOver();

      final step = flow.afterProof(attempt);

      expect(step.route, 'payments.collect');
      expect(step.parameters, {'shipmentId': attempt.shipment.value});
    });

    // Nobody collects for a parcel the courier took away again. The outcome
    // is sealed, so this fork is the compiler's to check.
    test('a failed visit leads back to the manifest, not to the money', () {
      final attempt = _value(
        _attempt().failWith(
          reason: const NonDeliveryReason.recipientAbsent(),
          at: DateTime.utc(2026, 8, 30, 9, 30),
        ),
      );

      expect(flow.afterProof(attempt).route, 'shipments.courier.manifest');
    });

    test('a finished door leads back to the manifest', () {
      expect(flow.afterDoor().route, 'shipments.courier.manifest');
    });
  });

  group('every destination the flow names', () {
    late GetIt container;
    late PeykRouter router;

    setUp(() async {
      container = await configureCourier(testPlatform());
      router = buildCourierRouter(container);
    });

    tearDown(() => container.reset());

    // The test that pays for the whole design. A route name is a string, and
    // this is the check that a typed one fails in CI rather than under a
    // courier's thumb. Scattered `context.goNamed` calls in fourteen
    // presentation packages could not be checked this way: no single package
    // knows what the app mounted.
    test('is a route this app actually mounted', () {
      expect(CourierFlow.destinations, isNotEmpty);
      for (final destination in CourierFlow.destinations) {
        expect(
          router.definitions.keys,
          contains(destination),
          reason:
              'CourierFlow names $destination, which this app does not '
              'declare. Either the route was renamed or the flow was typed.',
        );
      }
    });

    // A destination the app declares but never draws resolves to a blank
    // page, and courierUnmountedRoutes is the list of the ones it declares on
    // purpose. A flow step landing on one of those would be a blank screen at
    // the end of a real transition.
    test('is drawn rather than merely declared', () {
      expect(
        CourierFlow.destinations.intersection(router.unmounted),
        isEmpty,
      );
    });
  });
}

DeliveryAttempt _handedOver() => _value(
  DeliveryFixtures.attempt().completeWith(
    proof: DeliveryFixtures.fullProof(),
    reference: DeliveryFixtures.reference(),
    at: DeliveryFixtures.noon,
  ),
);

DeliveryAttempt _attempt() => DeliveryFixtures.attempt();

ActorId _actor() => _value(ActorId.parse('courier-7'));

/// Unwraps a `parse` that cannot fail on a literal the test controls.
///
/// The `parse` factories return a `Result` and never throw — rule 1.2.9 — so
/// a test that wants the value has to say what it expects. A `!` on a nullable
/// would say less: this names the failure if a valid literal ever stops being
/// one.
S _value<S, F>(Result<S, F> parsed) => parsed.fold(
  (value) => value,
  (failure) => throw StateError('the fixture no longer parses: $failure'),
);
