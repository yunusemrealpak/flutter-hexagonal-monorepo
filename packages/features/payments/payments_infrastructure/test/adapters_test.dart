@Tags(['unit'])
library;

import 'package:core_ports/core_ports.dart';
import 'package:core_testing/core_testing.dart';
import 'package:http_dio/http_dio.dart';
import 'package:payments_api/payments_api.dart';
import 'package:payments_infrastructure/payments_infrastructure.dart';
import 'package:payments_testing/payments_testing.dart';
import 'package:test/test.dart';

void main() {
  late FakeHttpTransport transport;
  late InMemoryKeyValueStore store;

  setUp(() {
    transport = FakeHttpTransport();
    store = InMemoryKeyValueStore();
  });

  group('RestPaymentsGateway', () {
    late RestPaymentsGateway gateway;

    setUp(() => gateway = RestPaymentsGateway(transport: transport));

    test('puts a collection at its own idempotency key', () async {
      // The idempotency carried by the URL. An adapter that posted to a
      // collection would have to hope the server read a header.
      final attempt = PaymentsFixtures.taken();
      transport.enqueueJson(PaymentsMapper.attemptToDto(attempt).toJson());

      await gateway.collect(attempt);

      expect(transport.lastRequest!.method, HttpMethod.put);
      expect(
        transport.lastRequest!.path,
        '/payments/collections/pay-1',
      );
    });

    test(
      'reads the server s answer back rather than echoing its input',
      () async {
        // The server is the side that decides what was recorded, including
        // answering a retry with the first result.
        final sent = PaymentsFixtures.taken();
        transport.enqueueJson(
          PaymentsMapper.attemptToDto(
            PaymentsFixtures.taken(minorUnits: 1200),
          ).toJson(),
        );

        final answer = await gateway.collect(sent);

        expect(
          answer.fold((a) => a.amount, (f) => throw StateError('$f')),
          PaymentsFixtures.lira(1200),
        );
      },
    );

    test('a refusal is read out of the rejection, with its reason', () async {
      // A courier standing at a door has to be able to say why: "insufficient
      // funds" and "card expired" send them to different next steps.
      transport.enqueueFailure(
        const TransportRejected(
          HttpResponse(
            statusCode: 402,
            body: {'reason': 'insufficient funds'},
          ),
        ),
      );

      final refused = await gateway.collect(PaymentsFixtures.taken());

      final failure = refused.fold((_) => null, (f) => f)! as CollectionRefused;
      expect(failure.reason, 'insufficient funds');
    });

    test('an unreachable service is not a refusal', () async {
      // The distinction CollectOnDelivery acts on: cash survives one of these
      // and not the other.
      transport.enqueueFailure(const TransportOffline());

      final failed = await gateway.collect(PaymentsFixtures.taken());

      expect(failed.fold((_) => null, (f) => f), isA<PaymentsUnavailable>());
    });

    test('a parcel with nothing recorded reads as nothing', () async {
      transport.enqueueJson(null);

      final found = await gateway.attemptFor('SHP-9');

      expect(found.fold((a) => a, (f) => throw StateError('$f')), isNull);
    });
  });

  group('DeviceBackedPaymentsGateway', () {
    late DeviceBackedPaymentsGateway gateway;

    setUp(
      () => gateway = DeviceBackedPaymentsGateway(
        remote: RestPaymentsGateway(transport: transport),
        store: store,
      ),
    );

    test('answers from the device when the network is gone', () async {
      // The whole point of the decorator. Without it, CollectOnDelivery's
      // check before minting a key is worthless in a tunnel: the read fails,
      // the use case mints again, and the courier's second tap queues a second
      // collection.
      final attempt = PaymentsFixtures.taken();
      transport.enqueueFailure(const TransportOffline());
      await gateway.collect(attempt);

      transport.enqueueFailure(const TransportOffline());
      final found = await gateway.attemptFor('SHP-1');

      expect(
        found.fold((a) => a?.id.value, (f) => throw StateError('$f')),
        'pay-1',
      );
    });

    test('answers from the device when the server has nothing yet', () async {
      // A collection queued this morning is not on the server, and that is not
      // the same as never having happened.
      transport.enqueueFailure(const TransportOffline());
      await gateway.collect(PaymentsFixtures.taken());

      transport.enqueueJson(null);
      final found = await gateway.attemptFor('SHP-1');

      expect(
        found.fold((a) => a?.id.value, (f) => throw StateError('$f')),
        'pay-1',
      );
    });

    test('does not write down a refusal', () async {
      // Recording it locally would make the next tap find an intention the
      // server has on file as declined.
      transport.enqueueFailure(
        const TransportRejected(
          HttpResponse(statusCode: 402, body: {'reason': 'declined'}),
        ),
      );
      await gateway.collect(PaymentsFixtures.taken());

      transport.enqueueJson(null);
      final found = await gateway.attemptFor('SHP-1');

      expect(found.fold((a) => a, (f) => throw StateError('$f')), isNull);
    });

    test('prefers the server when the server has an answer', () async {
      transport.enqueueJson(
        PaymentsMapper.attemptToDto(
          PaymentsFixtures.taken(minorUnits: 9900),
        ).toJson(),
      );

      final found = await gateway.attemptFor('SHP-1');

      expect(
        found.fold((a) => a?.amount, (f) => throw StateError('$f')),
        PaymentsFixtures.lira(9900),
      );
    });

    test('a refund has no offline path', () async {
      // Handing back notes against a record nobody has confirmed is how an
      // operation loses money to a customer who asks twice.
      transport.enqueueFailure(const TransportOffline());

      final refused = await gateway.refund('pay-1');

      expect(refused.fold((_) => null, (f) => f), isA<PaymentsUnavailable>());
    });
  });

  group('KeyValueCashDrawer', () {
    late KeyValueCashDrawer drawer;

    setUp(() => drawer = KeyValueCashDrawer(store: store));

    test('a shift starts with an empty drawer, not a failure', () async {
      final balance = await drawer.balance();

      expect(
        balance.fold((m) => m.isZero, (f) => throw StateError('$f')),
        isTrue,
      );
    });

    test('keeps the total across a restart', () async {
      await drawer.accept(PaymentsFixtures.lira(4500));

      final afterRestart = KeyValueCashDrawer(store: store);
      final balance = await afterRestart.balance();

      expect(
        balance.fold((m) => m, (f) => throw StateError('$f')),
        PaymentsFixtures.lira(4500),
      );
    });

    test('refuses to release more than it holds, through Money', () async {
      // The same rule that refuses a negative collection anywhere else. An
      // adapter with an `if` of its own would be a second place for it to
      // drift.
      await drawer.accept(PaymentsFixtures.lira(1000));

      final refused = await drawer.release(PaymentsFixtures.lira(5000));

      expect(refused.fold((_) => null, (f) => f), isA<PaymentsFailure>());
    });

    test('a store that will not answer is a drawer failure', () async {
      store.failNextWith(const StoreUnavailable(detail: 'locked'));

      final refused = await drawer.balance();

      expect(
        refused.fold((_) => null, (f) => f),
        isA<CashDrawerUnavailable>(),
      );
    });
  });

  group('KeyValueReceiptPrinter', () {
    test(
      'keys a receipt by the intention, so a retry overwrites its own',
      () async {
        // A customer with two receipts for one payment is a customer with a
        // question nobody can answer.
        final printer = KeyValueReceiptPrinter(store: store);

        await printer.issue(PaymentsFixtures.taken());
        await printer.issue(PaymentsFixtures.taken());

        final keys = await store.keys();
        expect(
          keys.fold((k) => k, (f) => throw StateError('$f')),
          hasLength(1),
        );
      },
    );
  });
}
