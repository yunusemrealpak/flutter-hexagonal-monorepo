@Tags(['widget'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identity_api/identity_api.dart';
import 'package:identity_testing/identity_testing.dart';
import 'package:payments_api/payments_api.dart';
import 'package:payments_presentation/payments_presentation.dart';
import 'package:payments_testing/payments_testing.dart';
import 'package:shipments_api/shipments_api.dart';

/// A `PermissionChecker` a test can set, standing in for identity.
///
/// Four lines, and it is the entire coupling between this package and
/// identity's decision-making — the same four lines as in
/// `delivery_presentation` and `shipments_presentation_dispatcher`. That the
/// stand-in is identical in three features is what scenario 6 buys.
final class _Permissions implements PermissionChecker {
  _Permissions(this._granted);

  final Set<Permission> _granted;

  @override
  bool can(Permission permission) => _granted.contains(permission);
}

/// A `SessionReader` over one fixed session, or none.
final class _Session implements SessionReader {
  _Session(this.current);

  @override
  final Session? current;

  @override
  Stream<Session?> changes() => Stream.value(current);
}

/// A `PaymentsFacade` this test steers.
final class _Facade implements PaymentsFacade {
  Result<PaymentStatus, PaymentsFailure> status = const Success(
    PaymentStatus.nothingToCollect(),
  );
  Result<PaymentAttempt, PaymentsFailure>? collectAnswer;

  /// The amounts `collectOnDelivery` was asked for, in order.
  final List<Money> amounts = [];

  /// The methods it was asked for, in order.
  final List<PaymentMethod> methods = [];

  @override
  Future<Result<PaymentStatus, PaymentsFailure>> paymentStatusOf(
    ShipmentId shipment,
  ) async => status;

  @override
  Future<Result<PaymentAttempt, PaymentsFailure>> collectOnDelivery({
    required ShipmentId shipment,
    required ActorId courier,
    required Money amount,
    required PaymentMethod method,
  }) async {
    amounts.add(amount);
    methods.add(method);
    return collectAnswer ?? Success(PaymentsFixtures.taken());
  }

  /// Every other method of the port, which this test does not use.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

CollectionController _controller(
  _Facade facade, {
  Set<Permission> granted = const {Permission.collectPayment},
  bool signedIn = true,
}) => CollectionController(
  payments: facade,
  session: _Session(
    signedIn ? SessionBuilder().actor('courier-1').build() : null,
  ),
  permissions: _Permissions(granted),
);

void main() {
  late _Facade facade;
  late CollectionController controller;

  setUp(() {
    facade = _Facade();
    controller = _controller(facade);
    addTearDown(controller.dispose);
  });

  void owes(int minorUnits) => facade.status = Success(
    PaymentStatus.outstanding(PaymentsFixtures.lira(minorUnits)),
  );

  Future<void> load() => controller.load(PaymentsFixtures.shipment());

  group('CollectionController', () {
    test('a prepaid parcel has nothing to collect', () async {
      // Where this screen spends most of its life.
      await load();

      expect(controller.state, isA<NothingOwed>());
    });

    test('a settled collection is also nothing to collect', () async {
      // Settled, refunded and never-owed are one thing to a courier standing
      // at a door: there is nothing to do here.
      facade.status = Success(
        PaymentStatus.settled(
          amount: PaymentsFixtures.lira(4500),
          at: PaymentsFixtures.noon,
        ),
      );

      await load();

      expect(controller.state, isA<NothingOwed>());
    });

    test('reports what is owed', () async {
      owes(4500);

      await load();

      expect((controller.state as Owed).amount, PaymentsFixtures.lira(4500));
    });

    test(
      'collects the amount payments reported, not one it was told',
      () async {
        // The amount is read, never typed. A screen with a text field would be
        // exactly where a difference between the two got in.
        owes(4500);
        await load();

        await controller.collect(PaymentsFixtures.shipment());

        expect(facade.amounts.single, PaymentsFixtures.lira(4500));
      },
    );

    test('carries the method the courier chose', () async {
      owes(4500);
      await load();

      controller.takeBy(const PaymentMethod.card(last4: '4242'));
      await controller.collect(PaymentsFixtures.shipment());

      expect(facade.methods.single, isA<Card>());
    });

    test('defaults to cash', () async {
      // The case the feature is shaped around: a person holding money at a
      // door.
      owes(4500);
      await load();

      expect((controller.state as Owed).method, isA<Cash>());
    });

    test('refuses to take money without the grant', () async {
      // Scenario 6 where it bites. The use case does not check permissions, so
      // this is the last thing between an actor without the grant and a
      // recorded payment.
      final ungranted = _controller(facade, granted: const {});
      addTearDown(ungranted.dispose);
      owes(4500);
      await ungranted.load(PaymentsFixtures.shipment());

      await ungranted.collect(PaymentsFixtures.shipment());

      expect(ungranted.canCollect, isFalse);
      expect(facade.amounts, isEmpty);
    });

    test('asks nobody to pay when nobody is signed in', () async {
      final anonymous = _controller(facade, signedIn: false);
      addTearDown(anonymous.dispose);
      owes(4500);
      await anonymous.load(PaymentsFixtures.shipment());

      await anonymous.collect(PaymentsFixtures.shipment());

      expect(facade.amounts, isEmpty);
    });

    test('a refusal keeps the courier at the door', () async {
      // The money is still owed and the visit has not finished.
      facade.collectAnswer = const Failed(
        CollectionRefused(reason: 'insufficient funds'),
      );
      owes(4500);
      await load();

      await controller.collect(PaymentsFixtures.shipment());

      final state = controller.state as Owed;
      expect(state.refusal, isA<CollectionRefused>());
      expect(state.amount, PaymentsFixtures.lira(4500));
    });

    test('reports a status it could not read', () async {
      facade.status = const Failed(PaymentsUnavailable());

      await load();

      expect(controller.state, isA<CollectionFailed>());
    });
  });

  group('CollectionScreen', () {
    Widget screen({
      Set<Permission> granted = const {Permission.collectPayment},
    }) {
      final built = _controller(facade, granted: granted);
      addTearDown(built.dispose);
      return PeykTheme.wrap(
        child: CollectionScreen(
          controller: built,
          shipment: PaymentsFixtures.shipment(),
        ),
      );
    }

    testWidgets('draws the amount, with the currency s own scale', (
      tester,
    ) async {
      owes(4500);

      await tester.pumpWidget(screen());
      await tester.pump();

      expect(
        find.text(
          '${PaymentsStrings.owed}'
          '(minorUnits=4500, currency=TRY, scale=2)',
        ),
        findsOneWidget,
      );
    });

    testWidgets('hides the action without the grant', (tester) async {
      owes(4500);

      await tester.pumpWidget(screen(granted: const {}));
      await tester.pump();

      expect(find.text(PaymentsStrings.collect), findsNothing);
      expect(find.text(PaymentsStrings.methodCash), findsOneWidget);
    });

    testWidgets('takes the money when the row is tapped', (tester) async {
      owes(4500);

      await tester.pumpWidget(screen());
      await tester.pump();

      await tester.tap(find.text(PaymentsStrings.collect));
      await tester.pump();

      expect(
        find.textContaining(PaymentsStrings.taken),
        findsOneWidget,
      );
    });

    testWidgets('says there is nothing to collect on a prepaid parcel', (
      tester,
    ) async {
      await tester.pumpWidget(screen());
      await tester.pump();

      expect(find.text(PaymentsStrings.nothingOwed), findsOneWidget);
    });

    test('an amount crosses as minor units, a code and a scale', () {
      // No formatting and no float. Turning minor units into money needs a
      // locale, and the scale travels with the amount because a currency with
      // three minor-unit digits or none would break any formatter that
      // assumed a hundred.
      expect(CollectionScreen.amountArguments(PaymentsFixtures.lira(4500)), {
        'minorUnits': 4500,
        'currency': 'TRY',
        'scale': 2,
      });
      expect(CollectionScreen.amountArguments(PaymentsFixtures.lira(0)), {
        'minorUnits': 0,
        'currency': 'TRY',
        'scale': 2,
      });
    });

    test('asks for a different key for every failure', () {
      // Ten cases, ten keys — the reason PaymentsFailure is sealed.
      final keys = <PaymentsFailure>[
        const CollectionRefused(reason: 'insufficient funds'),
        const CashDrawerUnavailable(),
        const PaymentsUnavailable(),
        const AlreadySettled('pay-1'),
        const NoCollectionFor('SHP-1'),
        const RefundNotPossible(reason: 'never taken'),
        const SettlementUnavailable(),
        const SettlementClosed('courier-1:2026-03-14'),
        const CurrencyMismatch(expected: 'TRY', actual: 'EUR'),
        const MalformedPaymentValue(field: 'money', reason: 'is negative'),
      ].map(CollectionScreen.describe).toList();

      expect(keys.toSet(), hasLength(10));
      expect(PaymentsStrings.all, containsAll(keys));
    });

    // Money is where a wrong retry costs the most. A payment already taken
    // must not offer a button that would take it twice.
    test('a settled payment offers no retry', () {
      expect(CollectionScreen.canRetry(const AlreadySettled('pay-1')), isFalse);
      expect(
        CollectionScreen.canRetry(
          const CollectionRefused(reason: 'insufficient funds'),
        ),
        isFalse,
      );
      expect(CollectionScreen.canRetry(const PaymentsUnavailable()), isTrue);
    });
  });

  group('PaymentsRoutes', () {
    test('guards taking and giving back with different permissions', () {
      // An operation that let every courier refund would have no way to tell a
      // mistake from a theft.
      const module = PaymentsRoutes();

      expect(module.moduleName, 'payments');
      expect(
        module.routes.map((route) => route.requiredPermission),
        ['collectPayment', 'refundPayment'],
      );
    });
  });
}
