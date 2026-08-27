@Tags(['widget'])
library;

import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
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
  Widget screen(SignInController controller) =>
      PeykTheme.wrap(child: SignInScreen(controller: controller));

  testWidgets('renders the session once it arrives', (tester) async {
    final facade = _Facade(Success(session))..gate.complete();
    final controller = SignInController(identity: facade);
    addTearDown(controller.dispose);

    await tester.pumpWidget(screen(controller));
    await controller.submit(credentials);
    await tester.pumpAndSettle();

    expect(
      find.textContaining(IdentityStrings.signedInAs),
      findsOneWidget,
    );
    expect(find.textContaining('Ali Veli'), findsOneWidget);
  });

  test('a second submit while one is in flight is ignored', () async {
    // Without this, a double tap on a slow connection sends two sign-ins and
    // the second one's session replaces the first's — including its device
    // binding, which the two requests may not agree about.
    final facade = _Facade(Success(session));
    final controller = SignInController(identity: facade);
    addTearDown(controller.dispose);

    final first = controller.submit(credentials);
    final second = controller.submit(credentials);
    facade.gate.complete();
    await Future.wait([first, second]);

    expect(facade.attempts, 1);
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
