@Tags(['unit'])
library;

import 'package:payments_api/payments_api.dart';
import 'package:payments_testing/payments_testing.dart';
import 'package:test/test.dart';

void main() {
  // The kits this package publishes, run against the fakes it publishes beside
  // them. That the fakes pass the same suites as the real adapters is what
  // makes them evidence that the kits are about correctness rather than about
  // one implementation's habits.
  group('FakePaymentsGateway', () {
    runPaymentsGatewayContract(FakePaymentsGateway.new);
  });

  group('InMemorySettlementStore', () {
    runSettlementStoreContract(InMemorySettlementStore.new);
  });

  group('FakePaymentsGateway', () {
    test('a refusal is not an unreachable server', () async {
      // The distinction the caller has to make, so the fake has to be able to
      // produce it: the gateway answered every question it was asked and said
      // no to one of them.
      final gateway = FakePaymentsGateway()
        ..refuseNextCollectionWith(
          const CollectionRefused(reason: 'insufficient funds'),
        );

      final read = await gateway.attemptFor('SHP-1');
      final refused = await gateway.collect(PaymentsFixtures.taken());

      expect(read.fold((a) => a, (f) => throw StateError('$f')), isNull);
      expect(refused.fold((_) => null, (f) => f), isA<CollectionRefused>());
    });
  });

  group('FakeCashDrawer', () {
    test('refuses to release more than it holds', () async {
      // Through Money.minus, which is the same rule that refuses a negative
      // amount anywhere else. A drawer that went negative would hide a caller
      // giving back money it never took.
      final drawer = FakeCashDrawer(PaymentsFixtures.lira(1000));

      final refused = await drawer.release(PaymentsFixtures.lira(5000));

      expect(refused.fold((_) => null, (f) => f), isA<PaymentsFailure>());
    });

    test('keeps a running total', () async {
      final drawer = FakeCashDrawer(PaymentsFixtures.noLira);

      await drawer.accept(PaymentsFixtures.lira(4500));
      await drawer.accept(PaymentsFixtures.lira(1200));
      await drawer.release(PaymentsFixtures.lira(200));

      expect(
        (await drawer.balance()).fold((m) => m, (f) => throw StateError('$f')),
        PaymentsFixtures.lira(5500),
      );
    });
  });

  group('FakePaymentStatusReader', () {
    test('says nothing is owed until it is told otherwise', () async {
      // Most parcels are prepaid, and a fixture that has to be told the
      // ordinary case before it can be used is a fixture nobody uses.
      final reader = FakePaymentStatusReader();

      final status = await reader.statusFor(PaymentsFixtures.shipment());

      expect(
        status.fold((s) => s, (f) => throw StateError('$f')),
        isA<NothingToCollect>(),
      );
    });

    test('reports what is outstanding', () async {
      final reader = FakePaymentStatusReader()
        ..owes('SHP-1', PaymentsFixtures.lira(4500));

      final status = await reader.statusFor(PaymentsFixtures.shipment());

      expect(
        status.fold((s) => s.isOutstanding, (f) => throw StateError('$f')),
        isTrue,
      );
      expect(reader.asked, ['SHP-1']);
    });
  });
}
