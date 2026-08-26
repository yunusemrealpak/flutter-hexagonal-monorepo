@Tags(['unit'])
library;

import 'dart:convert';

import 'package:core_kernel/core_kernel.dart';
import 'package:delivery_api/delivery_api.dart';
import 'package:payments_api/payments_api.dart';
import 'package:payments_application/payments_application.dart';
import 'package:payments_testing/payments_testing.dart';
import 'package:test/test.dart';

import 'support/harness.dart';

DeliveryCompleted _delivered({
  String shipmentId = 'SHP-1',
  DateTime? at,
}) => DeliveryCompleted(
  shipment: PaymentsFixtures.shipment(shipmentId),
  courier: PaymentsFixtures.courier(),
  proofReference: 'proof-1',
  occurredAt: at ?? PaymentsFixtures.noon,
);

void main() {
  late Harness harness;

  setUp(() {
    harness = Harness();
    addTearDown(harness.dispose);
  });

  group('CollectionReconciler', () {
    test(
      'closes an outstanding cash collection when its delivery lands',
      () async {
        // Scenario 2, end to end inside payments: delivery published, payments
        // reacted, and neither _application package names the other.
        await harness.gateway.collect(PaymentsFixtures.attempt());
        final reconciler = harness.reconciler;

        await reconciler.reconcile(_delivered());

        final attempt = await harness.gateway.attemptFor('SHP-1');
        expect(
          attempt.fold((a) => a!.outcome, (f) => throw StateError('$f')),
          isA<PaymentTaken>(),
        );
      },
    );

    test('stamps the closing with domain time, not arrival time', () async {
      // When the hand-over happened, not when this subscriber heard about it.
      // The two are hours apart when a delivery is drained from an outbox.
      final morning = PaymentsFixtures.noon.subtract(const Duration(hours: 3));
      await harness.gateway.collect(PaymentsFixtures.attempt());

      await harness.reconciler.reconcile(_delivered(at: morning));

      final attempt = await harness.gateway.attemptFor('SHP-1');
      expect(
        (attempt.fold((a) => a!.outcome, (f) => throw StateError('$f'))
                as PaymentTaken)
            .at,
        morning,
      );
    });

    test('adds the closed collection to the day', () async {
      await harness.gateway.collect(PaymentsFixtures.attempt());

      await harness.reconciler.reconcile(_delivered());

      expect(
        harness.settlements.stored.single.collected,
        PaymentsFixtures.lira(4500),
      );
    });

    test('running twice is free', () async {
      // Not by remembering what it has seen: the gateway is idempotent by key
      // and an already-settled collection is left alone. Redelivery, a late
      // drain and a resubscribe on resume all cost nothing.
      await harness.gateway.collect(PaymentsFixtures.attempt());
      final reconciler = harness.reconciler;

      await reconciler.reconcile(_delivered());
      await reconciler.reconcile(_delivered());

      expect(harness.gateway.recorded, 1);
      expect(
        harness.settlements.stored.single.collected,
        PaymentsFixtures.lira(4500),
      );
    });

    test('a prepaid parcel is the ordinary case, not a problem', () async {
      await harness.reconciler.reconcile(_delivered(shipmentId: 'SHP-9'));

      expect(harness.settlements.stored, isEmpty);
      expect(harness.logger.records, isEmpty);
    });

    test('leaves a collection that already settled alone', () async {
      await harness.gateway.collect(PaymentsFixtures.taken());

      await harness.reconciler.reconcile(_delivered());

      expect(harness.settlements.stored, isEmpty);
    });

    test('does not authorise a card because a parcel arrived', () async {
      // Inventing an authorisation would be inventing money.
      await harness.gateway.collect(
        PaymentsFixtures.attempt(
          method: const PaymentMethod.card(last4: '4242'),
        ),
      );

      await harness.reconciler.reconcile(_delivered());

      final attempt = await harness.gateway.attemptFor('SHP-1');
      expect(
        attempt.fold((a) => a!.outcome, (f) => throw StateError('$f')),
        isA<PaymentPending>(),
      );
    });

    test('reports rather than retries when it cannot read', () async {
      // The event has already been consumed. A reconciler that swallowed a
      // failure quietly would leave a collection open with nobody knowing;
      // the daily settlement is where a human notices.
      harness.gateway.failNextWith(const PaymentsUnavailable());

      await harness.reconciler.reconcile(_delivered());

      expect(harness.logger.records, isNotEmpty);
    });

    test('subscribes once, however many times it is started', () async {
      final reconciler = harness.reconciler;
      addTearDown(reconciler.dispose);
      await harness.gateway.collect(PaymentsFixtures.attempt());

      reconciler
        ..start()
        ..start();
      harness.events.publish(_delivered());
      await Future<void>.delayed(Duration.zero);

      expect(harness.gateway.recorded, 1);
      expect(
        harness.settlements.stored.single.collected,
        PaymentsFixtures.lira(4500),
      );
    });

    test('hears an event published on the bus', () async {
      // The wiring itself: delivery publishes, payments reacts, and the only
      // thing between them is a port in core_ports.
      final reconciler = harness.reconciler;
      addTearDown(reconciler.dispose);
      await harness.gateway.collect(PaymentsFixtures.attempt());
      reconciler.start();

      harness.events.publish(_delivered());
      await Future<void>.delayed(Duration.zero);

      final attempt = await harness.gateway.attemptFor('SHP-1');
      expect(
        attempt.fold((a) => a!.outcome, (f) => throw StateError('$f')),
        isA<PaymentTaken>(),
      );
    });
  });

  group('PaymentStatusOf', () {
    test('a parcel nobody collected against owes nothing', () async {
      // Most parcels are prepaid, and an operation whose shipment screen
      // showed an error for the ordinary case would have taught everybody to
      // ignore it.
      final status = await harness.statusOf(PaymentsFixtures.shipment());

      expect(
        status.fold((s) => s, (f) => throw StateError('$f')),
        isA<NothingToCollect>(),
      );
    });

    test('a pending collection is outstanding', () async {
      await harness.gateway.collect(PaymentsFixtures.attempt());

      final status = await harness.statusOf(PaymentsFixtures.shipment());

      expect(
        status.fold((s) => s.isOutstanding, (f) => throw StateError('$f')),
        isTrue,
      );
    });

    test('a refused collection is still outstanding', () async {
      // Why the operation is still waiting is payments' business. That it is
      // still waiting is the only part shipments cares about.
      final refused = PaymentsFixtures.attempt()
          .refused(reason: 'insufficient funds')
          .fold((a) => a, (f) => throw StateError('$f'));
      await harness.gateway.collect(refused);

      final status = await harness.statusOf(PaymentsFixtures.shipment());

      expect(
        status.fold((s) => s.isOutstanding, (f) => throw StateError('$f')),
        isTrue,
      );
    });

    test(
      'a taken collection is settled, with the amount and the moment',
      () async {
        await harness.gateway.collect(PaymentsFixtures.taken());

        final status = await harness.statusOf(PaymentsFixtures.shipment());

        final settled =
            status.fold((s) => s, (f) => throw StateError('$f'))
                as SettledInFull;
        expect(settled.amount, PaymentsFixtures.lira(4500));
        expect(settled.at, PaymentsFixtures.noon);
      },
    );
  });

  group('RefundCollection', () {
    test('gives the money back and takes it out of the drawer', () async {
      await harness.gateway.collect(PaymentsFixtures.taken());
      await harness.drawer.accept(PaymentsFixtures.lira(4500));

      final refunded = await harness.refund(PaymentsFixtures.key());

      expect(
        refunded.fold((a) => a.outcome, (f) => throw StateError('$f')),
        isA<PaymentRefunded>(),
      );
      expect(harness.drawer.released.single, PaymentsFixtures.lira(4500));
    });

    test('asks the gateway before it opens the drawer', () async {
      // The other order would leave a courier short by the amount of any
      // refund the operation then refused, and they are the one holding the
      // notes.
      final refused = await harness.refund(PaymentsFixtures.key('unknown'));

      expect(refused, isA<Failed<PaymentAttempt, PaymentsFailure>>());
      expect(harness.drawer.released, isEmpty);
    });

    test('a card refund never touches the drawer', () async {
      await harness.gateway.collect(
        PaymentsFixtures.taken(
          method: const PaymentMethod.card(last4: '4242'),
        ),
      );

      await harness.refund(PaymentsFixtures.key());

      expect(harness.drawer.released, isEmpty);
    });
  });

  group('CloseDailySettlement', () {
    test('hands in a day that was collected on', () async {
      await harness.collect((
        shipment: PaymentsFixtures.shipment(),
        courier: PaymentsFixtures.courier(),
        amount: PaymentsFixtures.lira(4500),
        method: const PaymentMethod.cash(),
      ));

      final closed = await harness.closeDay((
        courier: PaymentsFixtures.courier(),
        day: PaymentsFixtures.noon,
      ));

      final day = closed.fold((s) => s, (f) => throw StateError('$f'));
      expect(day.isOpen, isFalse);
      expect(day.collected, PaymentsFixtures.lira(4500));
    });

    test(
      'a day nobody collected on is closed empty, not reported missing',
      () async {
        // A courier who took no cash still hands in a day, and an operation
        // that could not tell "no collections" from "no record" would chase
        // both.
        final closed = await harness.closeDay((
          courier: PaymentsFixtures.courier(),
          day: PaymentsFixtures.noon,
        ));

        expect(
          closed.fold((s) => s.collected.isZero, (f) => throw StateError('$f')),
          isTrue,
        );
      },
    );

    test('a day closes once', () async {
      await harness.closeDay((
        courier: PaymentsFixtures.courier(),
        day: PaymentsFixtures.noon,
      ));

      final again = await harness.closeDay((
        courier: PaymentsFixtures.courier(),
        day: PaymentsFixtures.noon,
      ));

      expect(
        (again as Failed<Settlement, PaymentsFailure>).failure,
        isA<SettlementClosed>(),
      );
    });

    test('does not recount what the afternoon already added up', () async {
      // A closing step that recomputed from the attempts would be a second
      // source of truth for the same number — the one that disagrees at six
      // o'clock with a day nobody can reopen.
      harness.settlements.seed(
        PaymentsFixtures.day()
            .including(PaymentsFixtures.taken(minorUnits: 9900))
            .fold((s) => s, (f) => throw StateError('$f')),
      );

      final closed = await harness.closeDay((
        courier: PaymentsFixtures.courier(),
        day: PaymentsFixtures.noon,
      ));

      expect(
        closed.fold((s) => s.collected, (f) => throw StateError('$f')),
        PaymentsFixtures.lira(9900),
      );
    });
  });

  group('PaymentsCoordinator', () {
    test('answers the same question under both of its names', () async {
      // One object, two interfaces. shipments_application receives it as the
      // reader, so it can ask what is owed and cannot take money.
      final coordinator = harness.coordinator;
      addTearDown(coordinator.dispose);
      await harness.gateway.collect(PaymentsFixtures.taken());

      final asFacade = await coordinator.paymentStatusOf(
        PaymentsFixtures.shipment(),
      );
      final asReader = await coordinator.statusFor(PaymentsFixtures.shipment());

      expect(
        asFacade.fold((s) => s, (f) => throw StateError('$f')),
        asReader.fold((s) => s, (f) => throw StateError('$f')),
      );
    });

    test('announces an attempt that moved, and nothing else', () async {
      final coordinator = harness.coordinator;
      addTearDown(coordinator.dispose);

      final seen = <PaymentAttempt>[];
      coordinator.changes().listen(seen.add);

      await coordinator.collectOnDelivery(
        shipment: PaymentsFixtures.shipment(),
        courier: PaymentsFixtures.courier(),
        amount: PaymentsFixtures.lira(4500),
        method: const PaymentMethod.cash(),
      );
      await coordinator.paymentStatusOf(PaymentsFixtures.shipment());
      await Future<void>.delayed(Duration.zero);

      expect(seen, hasLength(1));
    });
  });

  group('CollectPaymentCommand', () {
    test('carries the key that makes the queue safe to retry', () async {
      final body =
          jsonDecode(CollectPaymentCommand(PaymentsFixtures.taken()).payload)
              as Map<String, Object?>;

      expect(body['idempotencyKey'], 'pay-1');
      expect(body['minorUnits'], 4500);
      expect(body['currency'], 'TRY');
      expect(body['method'], 'cash');
    });

    test('carries four digits of a card and no more', () async {
      // A payments feature that queued a full card number would put every
      // device holding an outbox inside a compliance scope nobody signed up
      // for.
      final command = CollectPaymentCommand(
        PaymentsFixtures.taken(
          method: const PaymentMethod.card(last4: '4242'),
        ),
      );

      final body = jsonDecode(command.payload) as Map<String, Object?>;
      expect(body['last4'], '4242');
      expect(command.payload, isNot(contains('pan')));
    });

    test('is its own routing key', () {
      expect(
        CollectPaymentCommand(PaymentsFixtures.taken()).type,
        'payments.collect',
      );
      expect(
        CollectPaymentCommand(PaymentsFixtures.taken()).type,
        isNot('delivery.completeAttempt'),
      );
    });
  });
}
