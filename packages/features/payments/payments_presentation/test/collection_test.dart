@Tags(['widget'])
library;

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:core_kernel/core_kernel.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  /// Held open, `collectOnDelivery` does not return until the test says so.
  ///
  /// The only way to observe a transformer: a policy about concurrent work is
  /// invisible unless two events genuinely overlap.
  Completer<void>? gate;

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
    await gate?.future;
    return collectAnswer ?? Success(PaymentsFixtures.taken());
  }

  /// Every other method of the port, which this test does not use.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Facade facade;

  setUp(() => facade = _Facade());

  CollectionBloc build({
    Set<Permission> granted = const {Permission.collectPayment},
    bool signedIn = true,
  }) => CollectionBloc(
    payments: facade,
    session: _Session(
      signedIn ? SessionBuilder().actor('courier-1').build() : null,
    ),
    permissions: _Permissions(granted),
  );

  void owes(int minorUnits) => facade.status = Success(
    PaymentStatus.outstanding(PaymentsFixtures.lira(minorUnits)),
  );

  CollectionRequested request() =>
      CollectionRequested(PaymentsFixtures.shipment());
  CollectionSubmitted submit() =>
      CollectionSubmitted(PaymentsFixtures.shipment());

  group('CollectionState', () {
    // The trap that makes state equality dangerous in this workspace, and the
    // reason Collected compares with identical. Entity in core_kernel compares
    // by identifier on purpose, so two attempts under the same idempotency key
    // are `==` however different their contents. A state that delegated to
    // that would let Bloc drop the emission and leave the old figure drawn.
    test('an updated attempt is not the state it replaced', () {
      final first = PaymentsFixtures.taken(minorUnits: 1000);
      final second = PaymentsFixtures.taken(minorUnits: 9900);

      // The premise: the domain calls these the same attempt.
      expect(first, second);

      // The state must not.
      expect(Collected(first), isNot(Collected(second)));
      expect(Collected(first), Collected(first));
    });

    test('a value-only state compares by value', () {
      // Owed carries Money, PaymentMethod and PaymentsFailure — none of them
      // an entity — so plain equality is the right answer and is what makes
      // an identical re-emission cost no rebuild.
      expect(
        Owed(PaymentsFixtures.lira(4500)),
        Owed(PaymentsFixtures.lira(4500)),
      );
      expect(
        Owed(PaymentsFixtures.lira(4500)),
        isNot(Owed(PaymentsFixtures.lira(9900))),
      );
    });
  });

  group('CollectionBloc', () {
    blocTest<CollectionBloc, CollectionState>(
      'a prepaid parcel has nothing to collect',
      // Where this screen spends most of its life.
      build: build,
      act: (bloc) => bloc.add(request()),
      expect: () => const [CollectionLoading(), NothingOwed()],
    );

    blocTest<CollectionBloc, CollectionState>(
      'a settled collection is also nothing to collect',
      // Settled, refunded and never-owed are one thing to a courier standing
      // at a door: there is nothing to do here.
      setUp: () => facade.status = Success(
        PaymentStatus.settled(
          amount: PaymentsFixtures.lira(4500),
          at: PaymentsFixtures.noon,
        ),
      ),
      build: build,
      act: (bloc) => bloc.add(request()),
      expect: () => const [CollectionLoading(), NothingOwed()],
    );

    blocTest<CollectionBloc, CollectionState>(
      'reports what is owed',
      setUp: () => owes(4500),
      build: build,
      act: (bloc) => bloc.add(request()),
      expect: () => [
        const CollectionLoading(),
        Owed(PaymentsFixtures.lira(4500)),
      ],
    );

    blocTest<CollectionBloc, CollectionState>(
      'reports a status it could not read',
      setUp: () => facade.status = const Failed(PaymentsUnavailable()),
      build: build,
      act: (bloc) => bloc.add(request()),
      expect: () => const [
        CollectionLoading(),
        CollectionFailed(PaymentsUnavailable()),
      ],
    );

    blocTest<CollectionBloc, CollectionState>(
      'defaults to cash',
      // The case the feature is shaped around: a person holding money at a
      // door.
      setUp: () => owes(4500),
      build: build,
      act: (bloc) => bloc.add(request()),
      verify: (bloc) => expect((bloc.state as Owed).method, isA<Cash>()),
    );

    test(
      'collects the amount payments reported, not one it was told',
      () async {
        // The amount is read, never typed. A screen with a text field would be
        // exactly where a difference between the two got in.
        owes(4500);
        final bloc = build();
        addTearDown(bloc.close);

        bloc.add(request());
        await pumpEventQueue();
        bloc.add(submit());
        await pumpEventQueue();

        expect(facade.amounts.single, PaymentsFixtures.lira(4500));
      },
    );

    test('carries the method the courier chose', () async {
      owes(4500);
      final bloc = build();
      addTearDown(bloc.close);

      bloc.add(request());
      await pumpEventQueue();
      bloc.add(const MethodChosen(PaymentMethod.card(last4: '4242')));
      await pumpEventQueue();
      bloc.add(submit());
      await pumpEventQueue();

      expect(facade.methods.single, isA<Card>());
    });

    test('refuses to take money without the grant', () async {
      // Scenario 6 where it bites. The use case does not check permissions, so
      // this is the last thing between an actor without the grant and a
      // recorded payment.
      owes(4500);
      final bloc = build(granted: const {});
      addTearDown(bloc.close);

      bloc.add(request());
      await pumpEventQueue();
      bloc.add(submit());
      await pumpEventQueue();

      expect(bloc.canCollect, isFalse);
      expect(facade.amounts, isEmpty);
    });

    test('asks nobody to pay when nobody is signed in', () async {
      owes(4500);
      final bloc = build(signedIn: false);
      addTearDown(bloc.close);

      bloc.add(request());
      await pumpEventQueue();
      bloc.add(submit());
      await pumpEventQueue();

      expect(facade.amounts, isEmpty);
    });

    test('a refusal keeps the courier at the door', () async {
      // The money is still owed and the visit has not finished.
      facade.collectAnswer = const Failed(
        CollectionRefused(reason: 'insufficient funds'),
      );
      owes(4500);
      final bloc = build();
      addTearDown(bloc.close);

      bloc.add(request());
      await pumpEventQueue();
      bloc.add(submit());
      await pumpEventQueue();

      final state = bloc.state as Owed;
      expect(state.refusal, isA<CollectionRefused>());
      expect(state.amount, PaymentsFixtures.lira(4500));
    });

    // The one behavioural change in the migration, and the reason this is a
    // Bloc rather than a Cubit. `droppable()` is a policy about concurrent
    // work and a method call has nowhere to carry one.
    //
    // Re-run with the transformer removed from `on<CollectionSubmitted>` and
    // this fails with two amounts: collectOnDelivery takes no idempotency key
    // from here, so the second call is a second payment.
    test('a second tap while the first is in flight is dropped', () async {
      owes(4500);
      facade.gate = Completer<void>();
      final bloc = build();
      addTearDown(bloc.close);

      bloc.add(request());
      await pumpEventQueue();

      bloc
        ..add(submit())
        ..add(submit());
      await pumpEventQueue();

      expect(facade.amounts, hasLength(1));

      facade.gate!.complete();
      await pumpEventQueue();

      expect(facade.amounts, hasLength(1));
      expect(bloc.state, isA<Collected>());
    });

    // The other transformer. Asking about a second parcel abandons the answer
    // to the first, so a slow read cannot land after a fast one and put the
    // previous door's amount on screen.
    test('a second read replaces the first rather than racing it', () async {
      owes(4500);
      final bloc = build();
      addTearDown(bloc.close);

      bloc
        ..add(request())
        ..add(request());
      await pumpEventQueue();

      // restartable() cancels the first handler, so only the surviving one
      // reaches a settled state.
      expect(bloc.state, Owed(PaymentsFixtures.lira(4500)));
    });
  });

  group('CollectionScreen', () {
    Widget screen({
      Set<Permission> granted = const {Permission.collectPayment},
      VoidCallback? onFinished,
    }) => PeykTheme.wrap(
      // The bloc arrives through the tree, exactly as an app supplies it.
      // BlocProvider closes it when the subtree goes away, so the test needs
      // no tear-down of its own.
      child: BlocProvider<CollectionBloc>(
        create: (_) => build(granted: granted),
        child: CollectionScreen(
          shipment: PaymentsFixtures.shipment(),
          onFinished: onFinished,
        ),
      ),
    );

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

    // What BlocSelector buys, asserted rather than asserted about. Choosing a
    // method emits a new Owed, and the outer builder's buildWhen refuses it
    // because the *kind* of state did not change — so only the two option rows
    // are rebuilt. The observable consequence is that the amount is still on
    // screen and correct, drawn by a subtree that was never asked to rebuild.
    testWidgets('choosing a method leaves the rest of the door alone', (
      tester,
    ) async {
      owes(4500);

      await tester.pumpWidget(screen());
      await tester.pump();

      await tester.tap(find.text(PaymentsStrings.methodCard));
      await tester.pump();

      expect(
        find.text(
          '${PaymentsStrings.takingBy}(method=${PaymentsStrings.methodCard})',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          '${PaymentsStrings.owed}'
          '(minorUnits=4500, currency=TRY, scale=2)',
        ),
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

    group('being done at the door', () {
      // Offered as a button rather than fired on a transition, and the
      // difference from ProofCaptureScreen.onSettled is the point:
      // NothingOwed arrives the instant the screen loads, so announcing it
      // automatically would take a prepaid parcel off the screen before
      // anybody read the word.
      testWidgets('a prepaid parcel offers the way onward', (tester) async {
        var finished = 0;

        await tester.pumpWidget(screen(onFinished: () => finished++));
        await tester.pumpAndSettle();

        expect(finished, isZero);

        await tester.tap(find.text(PaymentsStrings.done));
        await tester.pump();

        expect(finished, 1);
      });

      testWidgets('so does a parcel that was just paid for', (tester) async {
        owes(4500);
        var finished = 0;

        await tester.pumpWidget(screen(onFinished: () => finished++));
        await tester.pump();
        await tester.tap(find.text(PaymentsStrings.collect));
        await tester.pump();
        await tester.tap(find.text(PaymentsStrings.done));
        await tester.pump();

        expect(finished, 1);
      });

      // app_dispatcher mounts this package to show what was collected. There
      // is no door to leave and no flow to continue, so there is no button.
      testWidgets('an app with nowhere to go draws no button', (tester) async {
        await tester.pumpWidget(screen());
        await tester.pumpAndSettle();

        expect(find.text(PaymentsStrings.nothingOwed), findsOneWidget);
        expect(find.text(PaymentsStrings.done), findsNothing);
      });
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
