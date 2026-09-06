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
import 'package:identity_presentation/identity_presentation.dart';
import 'package:identity_testing/identity_testing.dart';

/// An `IdentityFacade` whose sign-in a test controls, including its timing.
final class _Facade implements IdentityFacade {
  _Facade(this._answer);

  final Result<Session, IdentityFailure> _answer;

  /// Completed by the test, so a pending state can be observed.
  final Completer<void> gate = Completer<void>();

  /// How many sign-ins were attempted.
  int attempts = 0;

  @override
  Future<Result<Session, IdentityFailure>> signIn(
    Credentials credentials,
  ) async {
    attempts++;
    await gate.future;
    return _answer;
  }

  /// Every other method of the port, which this test does not use.
  ///
  /// A stub rather than eleven `UnimplementedError` overrides. What it says is
  /// "this test is about one method"; a call to any other one throws, which is
  /// louder than an override returning a plausible empty value.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final session = SessionBuilder().build();
  final credentials = PasswordCredentials.create(
    actorId: 'courier-1',
    secret: 'hunter2',
  ).fold((c) => c, (f) => throw StateError('$f'));

  /// The tree the components need: a palette, the design system's delegates,
  /// and a catalogue. The default catalogue echoes keys, so an assertion below
  /// reads as a claim about *which* string the screen asked for rather than
  /// about an app's wording.
  /// The tree the screen needs, with the bloc **owned by the provider**.
  ///
  /// Never `BlocProvider.value` with a bloc the test closes itself. A widget
  /// test runs inside a fake-async zone, and `Bloc.close()` completes on
  /// microtasks scheduled in that zone — so awaiting it from the body, or from
  /// `addTearDown`, waits for a queue nothing is draining any more and the test
  /// hangs with no failure and no timeout. `BlocProvider(create:)` closes it
  /// while the tree is being disposed, which is inside the window. Plain
  /// `test` cases below are unaffected and use `addTearDown(bloc.close)`.
  Widget screen(IdentityFacade identity) => PeykTheme.wrap(
    child: BlocProvider<SignInBloc>(
      create: (_) => SignInBloc(identity: identity),
      child: const SignInScreen(),
    ),
  );

  testWidgets('renders the session once it arrives', (tester) async {
    final facade = _Facade(Success(session))..gate.complete();

    await tester.pumpWidget(screen(facade));
    // Dispatched through the tree, the way the app does it: nothing outside
    // this widget holds the bloc.
    tester
        .element(find.byType(SignInScreen))
        .read<SignInBloc>()
        .add(CredentialsSubmitted(credentials));
    // `pump`, never `pumpAndSettle`: the pending state draws a spinner, and
    // settling waits for an animation that is supposed to run forever. Two
    // frames, because the event is delivered in a microtask and the facade's
    // answer arrives in the next one.
    await tester.pump();
    await tester.pump();

    expect(
      find.textContaining(IdentityStrings.signedInAs),
      findsOneWidget,
    );
    expect(find.textContaining('Ali Veli'), findsOneWidget);
  });

  test('a second submit while one is in flight is dropped', () async {
    // Without this, a double tap on a slow connection sends two sign-ins and
    // the second one's session replaces the first's — including its device
    // binding, which the two requests may not agree about. `droppable()` is
    // the whole guard; remove the transformer and this reports two attempts.
    final facade = _Facade(Success(session));
    final bloc = SignInBloc(identity: facade);
    addTearDown(bloc.close);

    bloc
      ..add(CredentialsSubmitted(credentials))
      ..add(CredentialsSubmitted(credentials));
    await Future<void>.delayed(Duration.zero);
    facade.gate.complete();
    await bloc.stream.firstWhere((state) => state is SignedIn);

    expect(facade.attempts, 1);
  });

  blocTest<SignInBloc, SignInState>(
    'clearing a rejection returns the screen to the form',
    build: () => SignInBloc(
      identity: _Facade(const Failed(InvalidCredentials()))..gate.complete(),
    ),
    act: (bloc) async {
      bloc.add(CredentialsSubmitted(credentials));
      await bloc.stream.firstWhere((state) => state is SignInRejected);
      bloc.add(const SignInCleared());
    },
    // Matchers rather than instances, because `SignInState` deliberately
    // carries no `==`. Nothing this bloc emits is worth de-duplicating: every
    // transition changes the case, so equality would buy no suppressed rebuild
    // and would have to decide what two sessions being "the same" means — and
    // `Session.actor` is an entity, whose equality is its identifier alone.
    expect: () => [
      isA<SignInPending>(),
      isA<SignInRejected>().having(
        (state) => state.failure,
        'failure',
        const InvalidCredentials(),
      ),
      isA<SignInIdle>(),
    ],
  );

  test('clearing is refused while an attempt is in flight', () async {
    // `droppable()` covers a second submit and says nothing about a different
    // event arriving mid-flight. Without the guard the screen goes back to the
    // form and then moves off it again when the answer lands.
    final facade = _Facade(Success(session));
    final bloc = SignInBloc(identity: facade);
    addTearDown(bloc.close);

    // The gate is released at the end rather than left hanging: `close()`
    // waits for the handler that is still inside `signIn`, so a test that
    // walks away from an in-flight request hangs its own tear-down.
    addTearDown(facade.gate.complete);

    bloc.add(CredentialsSubmitted(credentials));
    await bloc.stream.firstWhere((state) => state is SignInPending);
    bloc.add(const SignInCleared());
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state, isA<SignInPending>());
  });

  group('what a rejection says', () {
    test('a wrong password and an unknown device say the same thing', () {
      // Distinguishing them tells an attacker whether the account exists.
      expect(
        SignInScreen.describe(const InvalidCredentials()),
        SignInScreen.describe(const DeviceNotRegistered('handset-9')),
      );
    });

    test('a broken binding is its own message', () {
      // Its own key rather than the shared rejection one: a person whose
      // device changed has something to do about it, and telling them the
      // details did not work would send them to check a password that is
      // fine.
      expect(
        SignInScreen.describe(
          const DeviceBindingBroken(
            deviceId: 'handset-1',
            expectedFingerprint: 'a',
            actualFingerprint: 'b',
          ),
        ),
        IdentityStrings.failureDeviceChanged,
      );
    });

    test('every failure maps to a key an app is asked to answer', () {
      final failures = <IdentityFailure>[
        const InvalidCredentials(),
        const NoSession(),
        const SessionExpired(),
        ActorDisabled(session.actor.id),
        const DeviceNotRegistered('handset-1'),
        const IdentityUnavailable(),
        const MalformedActorId(''),
        const MalformedAccessToken('empty'),
      ];

      for (final failure in failures) {
        // In IdentityStrings.all, so an app's catalogue coverage test is
        // holding it: a key no app answers is a screen showing its own key.
        expect(IdentityStrings.all, contains(SignInScreen.describe(failure)));
      }
    });
  });

  test('the sign-in route is the only one that needs no session', () {
    // A sign-in screen behind a session guard is a screen nobody can reach.
    const routes = IdentityRoutes();

    expect(routes.routes.single.requiresSession, isFalse);
  });
}
