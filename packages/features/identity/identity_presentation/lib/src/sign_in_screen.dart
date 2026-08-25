import 'package:flutter/widgets.dart';
import 'package:identity_api/identity_api.dart';

import 'sign_in_controller.dart';
import 'sign_in_state.dart';

/// The sign-in screen.
///
/// Plain on purpose: `design_system` arrives in phase 7, and inventing
/// colours and spacing here would mean deleting them then.
final class SignInScreen extends StatelessWidget {
  /// Creates the screen over [controller].
  const SignInScreen({required this.controller, super.key});

  /// What drives it.
  final SignInController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => Center(
      child: switch (controller.state) {
        SignInIdle() => const Text('Sign in to continue'),
        SignInPending() => const Text('Signing you in'),
        SignedIn(:final session) => Text(
          'Signed in as ${session.actor.displayName}',
        ),
        SignInRejected(:final failure) => Text(describe(failure)),
      },
    ),
  );

  /// Turns a failure into something the person holding the phone can act on.
  ///
  /// `InvalidCredentials` and `DeviceNotRegistered` render the same sentence,
  /// and that is a security decision rather than laziness: distinguishing them
  /// tells an attacker whether an account exists. It is made here, once, at
  /// the only place that produces text — not in the failure type, where every
  /// caller would have to remember it.
  @visibleForTesting
  static String describe(IdentityFailure failure) => switch (failure) {
    InvalidCredentials() || DeviceNotRegistered() =>
      'Those details did not work. Check them and try again.',
    DeviceBindingBroken() =>
      'This device has changed. Sign in again to re-register it.',
    SessionExpired() || NoSession() => 'Your session ended. Sign in again.',
    ActorDisabled() => 'This account is not active. Call the depot.',
    IdentityUnavailable() => 'No signal. Try again in a moment.',
    MalformedActorId() || MalformedAccessToken() =>
      'Something went wrong signing you in. Call the depot.',
  };
}
