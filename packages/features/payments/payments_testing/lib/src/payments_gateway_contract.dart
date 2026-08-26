import 'package:payments_api/payments_api.dart';
import 'package:test/test.dart';

import 'payments_fixtures.dart';

/// The behaviour every `PaymentsGateway` has to have.
///
/// **The first four tests are the specification's "idempotency (critical)"**
/// and they are the reason this kit exists. A courier taps *collect*, the
/// request times out, the phone retries: the far side must recognise the
/// second copy as the same intention and answer with the first one's result.
/// Held to that here, one suite runs against the fake and against the REST
/// adapter, which is the only way to know the two agree about the case a
/// courier actually meets.
///
/// What the kit deliberately does *not* assert is anything an implementation
/// arranges for itself — a network timeout, a 409 from a real acquirer. Those
/// belong in each adapter's own tests. A kit with a back door stops being
/// runnable against the other implementation, which is the whole reason to
/// have one.
///
/// [createGateway] must return a fresh, empty gateway on every call.
void runPaymentsGatewayContract(PaymentsGateway Function() createGateway) {
  group('PaymentsGateway contract', () {
    late PaymentsGateway gateway;

    setUp(() => gateway = createGateway());

    Future<PaymentAttempt> collect(PaymentAttempt attempt) async =>
        (await gateway.collect(attempt)).fold(
          (value) => value,
          (failure) => throw StateError('$failure'),
        );

    test('records what it was given', () async {
      final attempt = PaymentsFixtures.taken();

      final recorded = await collect(attempt);

      expect(recorded.id, attempt.id);
      expect(recorded.amount, PaymentsFixtures.lira(4500));
    });

    test('the same intention twice moves money once', () async {
      // The assertion the whole feature is shaped around. The second call
      // carries a *different* instant, so an implementation that recorded
      // again would be visible: the answer would carry the second one.
      final first = PaymentsFixtures.taken();
      final retry = PaymentsFixtures.taken(
        at: PaymentsFixtures.noon.add(const Duration(minutes: 3)),
      );

      final once = await collect(first);
      final again = await collect(retry);

      expect(again.id, once.id);
      expect(
        (again.outcome as PaymentTaken).at,
        (once.outcome as PaymentTaken).at,
        reason: 'the retry must be answered with the first result',
      );
    });

    test(
      'an intention recorded before the visit can be closed at it',
      () async {
        // The other half of the rule, and the case a stricter reading would
        // break: an operation records an expected cash amount against a parcel,
        // the courier takes it at the door, and the same key carries the
        // intention forward. A gateway that answered with the pending row would
        // leave every pre-recorded collection open for ever.
        await collect(PaymentsFixtures.attempt());

        final closed = await collect(PaymentsFixtures.taken());

        expect(closed.outcome, isA<PaymentTaken>());
        expect(closed.id.value, 'pay-1');
      },
    );

    test('two intentions are two movements', () async {
      // The other half of the rule. An implementation that deduplicated on the
      // shipment rather than the key would fail here — and would refuse a
      // customer who legitimately pays twice for one parcel, after a return.
      await collect(PaymentsFixtures.taken());
      final second = await collect(
        PaymentsFixtures.taken(keyValue: 'pay-2', minorUnits: 1200),
      );

      expect(second.amount, PaymentsFixtures.lira(1200));
      expect(second.id.value, 'pay-2');
    });

    test('finds the attempt recorded against a parcel', () async {
      // What makes an intention findable, which is what stops the *use case*
      // minting a second key on a retry.
      await collect(PaymentsFixtures.taken());

      final found = await gateway.attemptFor('SHP-1');

      expect(
        found.fold((a) => a?.id.value, (f) => throw StateError('$f')),
        'pay-1',
      );
    });

    test('a parcel nobody collected against reads as nothing', () async {
      // Most parcels are prepaid. A failure here would make the ordinary case
      // an error.
      final found = await gateway.attemptFor('SHP-9');

      expect(found.fold((a) => a, (f) => throw StateError('$f')), isNull);
    });

    test('gives back what was taken', () async {
      await collect(PaymentsFixtures.taken());

      final refunded = await gateway.refund('pay-1');

      expect(
        refunded.fold((a) => a.outcome, (f) => throw StateError('$f')),
        isA<PaymentRefunded>(),
      );
    });

    test('a refund is idempotent too', () async {
      // A courier whose refund request timed out will send it again, and
      // giving the money back twice is the same loss as taking it twice.
      await collect(PaymentsFixtures.taken());
      final first = await gateway.refund('pay-1');
      final again = await gateway.refund('pay-1');

      expect(
        (again.fold((a) => a.outcome, (f) => throw StateError('$f'))
                as PaymentRefunded)
            .refundedAt,
        (first.fold((a) => a.outcome, (f) => throw StateError('$f'))
                as PaymentRefunded)
            .refundedAt,
      );
    });

    test('refuses to give back money it never took', () async {
      final refused = await gateway.refund('pay-nothing');

      expect(refused.fold((_) => null, (failure) => failure), isNotNull);
    });
  });
}
