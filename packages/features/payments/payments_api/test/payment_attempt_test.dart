@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:payments_api/payments_api.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  group('PaymentAttempt', () {
    test('is identified by its idempotency key', () {
      // The design of the whole feature in one assertion. Two attempts with
      // the same key are the same attempt, so a double charge is a state the
      // type system cannot express rather than a bug to guard against.
      final first = Fixtures.attempt();
      final second = Fixtures.taken();

      expect(first, second);
      expect(first.id.value, 'pay-1');
    });

    test('two intentions are two attempts', () {
      expect(
        Fixtures.attempt(),
        isNot(Fixtures.attempt(keyValue: 'pay-2')),
      );
    });

    test('starts pending and outstanding', () {
      final attempt = Fixtures.attempt();

      expect(attempt.outcome, isA<PaymentPending>());
      expect(attempt.isSettled, isFalse);
      expect(attempt.isOutstanding, isTrue);
    });

    test('money moves once', () {
      // What stops a retry of a successful collection becoming a second one,
      // even if the key somehow reached the gateway twice.
      final again = Fixtures.taken().taken(at: Fixtures.noon);

      expect(
        (again as Failed<PaymentAttempt, PaymentsFailure>).failure,
        isA<AlreadySettled>(),
      );
    });

    test('a refusal is not final', () {
      // A declined card can be tried again under the same intention. Treating
      // a refusal as settled would leave a courier unable to take money the
      // customer is holding out.
      final refused = Fixtures.unwrap(
        Fixtures.attempt().refused(reason: 'insufficient funds'),
      );

      expect(refused.isSettled, isFalse);
      expect(refused.isOutstanding, isTrue);
      expect(
        refused.taken(at: Fixtures.noon),
        isA<Success<PaymentAttempt, PaymentsFailure>>(),
      );
    });

    test('a second refusal replaces the first message', () {
      // A customer who tried two cards produced two refusals under one
      // intention, and the second one is the useful message.
      final twice = Fixtures.unwrap(
        Fixtures.unwrap(
          Fixtures.attempt().refused(reason: 'expired'),
        ).refused(reason: 'insufficient funds'),
      );

      expect(
        (twice.outcome as PaymentRefused).reason,
        'insufficient funds',
      );
    });

    test('nothing is refunded that was not taken', () {
      // Giving back money that never arrived is a hole in a settlement nobody
      // can close.
      final refused = Fixtures.attempt().refunded(at: Fixtures.noon);

      expect(
        (refused as Failed<PaymentAttempt, PaymentsFailure>).failure,
        isA<RefundNotPossible>(),
      );
    });

    test('a refund keeps the taking as well as the giving back', () {
      // A refund is not the erasure of a payment. A settlement that forgot the
      // first half could not explain the second.
      final back = Fixtures.noon.add(const Duration(hours: 2));
      final refunded = Fixtures.unwrap(Fixtures.taken().refunded(at: back));

      final outcome = refunded.outcome as PaymentRefunded;
      expect(outcome.takenAt, Fixtures.noon);
      expect(outcome.refundedAt, back);
      expect(refunded.isOutstanding, isFalse);
    });

    test('a refund happens once', () {
      final refunded = Fixtures.unwrap(
        Fixtures.taken().refunded(at: Fixtures.noon),
      );

      expect(
        refunded.refunded(at: Fixtures.noon),
        isA<Failed<PaymentAttempt, PaymentsFailure>>(),
      );
    });
  });

  group('PaymentMethod', () {
    test('answers whether money passed through a courier s hands', () {
      // The question the drawer and the settlement both ask. Two copies of it
      // would disagree the first time a case was added.
      expect(const PaymentMethod.cash().isCash, isTrue);
      expect(const PaymentMethod.card(last4: '4242').isCash, isFalse);
      expect(const PaymentMethod.transfer(reference: 'x').isCash, isFalse);
    });
  });

  group('PaymentStatus', () {
    test('answers the one question shipments asks', () {
      // Behaviour on the union rather than a switch in the other feature — a
      // copy over there would be a copy nobody updates.
      expect(const PaymentStatus.nothingToCollect().isOutstanding, isFalse);
      expect(
        PaymentStatus.outstanding(Fixtures.lira(100)).isOutstanding,
        isTrue,
      );
      expect(
        PaymentStatus.settled(
          amount: Fixtures.lira(100),
          at: Fixtures.noon,
        ).isOutstanding,
        isFalse,
      );
    });
  });
}
