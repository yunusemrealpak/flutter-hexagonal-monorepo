@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:payments_api/payments_api.dart';
import 'package:payments_testing/payments_testing.dart';
import 'package:sync_api/sync_api.dart';
import 'package:test/test.dart';

import 'support/harness.dart';

void main() {
  late Harness harness;

  setUp(() {
    harness = Harness();
    addTearDown(harness.dispose);
  });

  Future<Result<PaymentAttempt, PaymentsFailure>> collect({
    int minorUnits = 4500,
    PaymentMethod method = const PaymentMethod.cash(),
  }) => harness.collect((
    shipment: PaymentsFixtures.shipment(),
    courier: PaymentsFixtures.courier(),
    amount: PaymentsFixtures.lira(minorUnits),
    method: method,
  ));

  group('CollectOnDelivery', () {
    test('takes the money, records it, prints and counts it', () async {
      final taken = (await collect()).fold(
        (value) => value,
        (failure) => throw StateError('$failure'),
      );

      expect(taken.outcome, isA<PaymentTaken>());
      expect(harness.gateway.recorded, 1);
      expect(harness.drawer.accepted.single, PaymentsFixtures.lira(4500));
      expect(harness.receipts.issued.single.id, taken.id);
      expect(
        harness.settlements.stored.single.collected,
        PaymentsFixtures.lira(4500),
      );
    });

    test(
      'two taps on one intention mint one key and move money once',
      () async {
        // The specification's "idempotency (critical)", at the layer that
        // decides what counts as the same intention. A use case that minted on
        // every call would produce a key per tap.
        final first = await collect();
        final second = await collect();

        expect(harness.ids.issuedCount, 1);
        expect(harness.gateway.recorded, 1);
        expect(
          first.fold((a) => a.id, (f) => throw StateError('$f')),
          second.fold((a) => a.id, (f) => throw StateError('$f')),
        );
      },
    );

    test('the second tap does not take the money again', () async {
      // The assertion that would fail if the use case reached the drawer
      // before it asked what the server already had.
      await collect();
      await collect();

      expect(harness.drawer.accepted, hasLength(1));
    });

    test(
      'a refusal leaves nothing recorded, so a retry is a new intention',
      () async {
        // Idempotency protects against an *uncertain* outcome — a timeout,
        // a lost acknowledgement — not against a known refusal. Nothing was
        // taken, so a fresh key on the retry is safe; reusing one would tie a
        // successful second attempt to a first the server has on file as
        // declined.
        harness.gateway.refuseNextCollectionWith(
          const CollectionRefused(reason: 'insufficient funds'),
        );

        await collect();
        await collect();

        expect(harness.gateway.recorded, 1);
        expect(harness.ids.issuedCount, 2);
      },
    );

    test('cash survives a gateway that cannot be reached', () async {
      // The money is already in the courier's hand and the server is only
      // being told. Refusing here would leave a courier holding notes the
      // operation has no record of.
      harness.gateway
        ..failNextWith(const PaymentsUnavailable(detail: 'offline'))
        ..failNextWith(const PaymentsUnavailable(detail: 'offline'));

      final taken = await collect();

      expect(taken, isA<Success<PaymentAttempt, PaymentsFailure>>());
      expect(harness.queue.types, ['payments.collect']);
    });

    test('a queued cash collection asks for a person', () async {
      // Two records of one cash collection are either a double charge or a
      // lost one, and neither is something a queue may decide on its own.
      harness.gateway
        ..failNextWith(const PaymentsUnavailable())
        ..failNextWith(const PaymentsUnavailable());

      await collect();

      expect(harness.queue.policies.single, isA<ManualReview>());
    });

    test('a card does not survive a gateway that cannot be reached', () async {
      // A card needs an acquirer to say yes. Reporting success without one
      // would be inventing money.
      harness.gateway.failNextWith(const PaymentsUnavailable());

      final refused = await collect(
        method: const PaymentMethod.card(last4: '4242'),
      );

      expect(refused, isA<Failed<PaymentAttempt, PaymentsFailure>>());
      expect(harness.queue.queued, isEmpty);
    });

    test('a refusal is never queued', () async {
      // A refusal is an answer, not a connection problem. Queueing it would
      // tell a courier the money was taken when an acquirer had just said no.
      harness.gateway.refuseNextCollectionWith(
        const CollectionRefused(reason: 'insufficient funds'),
      );

      final refused = await collect();

      expect(
        (refused as Failed<PaymentAttempt, PaymentsFailure>).failure,
        isA<CollectionRefused>(),
      );
      expect(harness.queue.queued, isEmpty);
    });

    test('cash accepted for a refused collection is given back', () async {
      harness.gateway.refuseNextCollectionWith(
        const CollectionRefused(reason: 'insufficient funds'),
      );

      await collect();

      expect(harness.drawer.released.single, PaymentsFixtures.lira(4500));
    });

    test('a card never touches the drawer', () async {
      await collect(method: const PaymentMethod.card(last4: '4242'));

      expect(harness.drawer.accepted, isEmpty);
    });

    test('a drawer that will not open stops the collection', () async {
      // The one failure before the money is recorded that has to be fatal: a
      // tally the courier cannot trust is worse than a collection that did not
      // happen.
      harness.drawer.failNextWith(
        const CashDrawerUnavailable(detail: 'jammed'),
      );

      final refused = await collect();

      expect(
        (refused as Failed<PaymentAttempt, PaymentsFailure>).failure,
        isA<CashDrawerUnavailable>(),
      );
      expect(harness.gateway.recorded, 0);
    });

    test('a receipt that will not print does not undo a collection', () async {
      // Money the courier is holding with no record of it is worse than a
      // customer with no slip of paper.
      harness.receipts.failNextWith(const PaymentsUnavailable());

      final taken = await collect();

      expect(taken, isA<Success<PaymentAttempt, PaymentsFailure>>());
      expect(harness.gateway.recorded, 1);
    });

    test(
      'a settlement that will not update does not undo a collection',
      () async {
        harness.settlements.failNextWith(const SettlementUnavailable());

        final taken = await collect();

        expect(taken, isA<Success<PaymentAttempt, PaymentsFailure>>());
      },
    );

    test(
      'an already settled collection is the answer, not a new one',
      () async {
        // The courier tapped twice, or a retry arrived after the first copy
        // landed.
        await harness.gateway.collect(PaymentsFixtures.taken());

        final answer = await collect();

        expect(harness.ids.issuedCount, 0);
        expect(harness.drawer.accepted, isEmpty);
        expect(
          answer.fold((a) => a.id.value, (f) => throw StateError('$f')),
          'pay-1',
        );
      },
    );

    test('an afternoon adds up in one day', () async {
      await collect();
      await harness.collect((
        shipment: PaymentsFixtures.shipment('SHP-2'),
        courier: PaymentsFixtures.courier(),
        amount: PaymentsFixtures.lira(1200),
        method: const PaymentMethod.cash(),
      ));

      expect(harness.settlements.stored, hasLength(1));
      expect(
        harness.settlements.stored.single.collected,
        PaymentsFixtures.lira(5700),
      );
    });
  });
}
