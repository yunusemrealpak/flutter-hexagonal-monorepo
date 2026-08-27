import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:identity_api/identity_api.dart';

import 'identity_strings.dart';
import 'sign_in_controller.dart';
import 'sign_in_state.dart';

/// The sign-in screen.
final class SignInScreen extends StatelessWidget {
  /// Creates the screen over [controller].
  const SignInScreen({required this.controller, super.key});

  /// What drives it.
  final SignInController controller;

  @override
  Widget build(BuildContext context) {
    final strings = PeykStrings.of(context);

    return PeykScreen(
      title: strings.resolve(IdentityStrings.signInTitle),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => Center(
          child: switch (controller.state) {
            SignInIdle() => PeykText.body(
              strings.resolve(IdentityStrings.signInIdle),
            ),
            SignInPending() => const PeykLoadingView(),
            SignedIn(:final session) => PeykText.body(
              strings.resolve(
                IdentityStrings.signedInAs,
                arguments: {'name': session.actor.displayName},
              ),
            ),
            SignInRejected(:final failure) => PeykFailureView(
              message: strings.resolve(describe(failure)),
              onRetry: canRetry(failure) ? controller.clear : null,
            ),
          },
        ),
      ),
    );
  }

  /// Which string a failure should be shown as.
  ///
  /// `InvalidCredentials` and `DeviceNotRegistered` map to the same key, and
  /// that is a security decision rather than laziness: distinguishing them
  /// tells an attacker whether an account exists. It is made here, once, at the
  /// only place that chooses a message — not in the failure type, where every
  /// caller would have to remember it.
  ///
  /// Returning a key rather than a sentence is what keeps that decision intact
  /// across apps. Two apps write two sets of words, but both write them behind
  /// one key, so neither can accidentally give the two failures different
  /// wording and leak the difference.
  @visibleForTesting
  static String describe(IdentityFailure failure) => switch (failure) {
    InvalidCredentials() ||
    DeviceNotRegistered() => IdentityStrings.failureRejected,
    DeviceBindingBroken() => IdentityStrings.failureDeviceChanged,
    SessionExpired() || NoSession() => IdentityStrings.failureSessionEnded,
    ActorDisabled() => IdentityStrings.failureDisabled,
    IdentityUnavailable() => IdentityStrings.failureUnavailable,
    MalformedActorId() ||
    MalformedAccessToken() => IdentityStrings.failureInternal,
  };

  /// Whether trying again is the answer to [failure].
  ///
  /// A disabled account is not fixed by another attempt, and neither is a
  /// malformed token: both need somebody at the depot. Offering a button there
  /// teaches a courier that the app is broken.
  @visibleForTesting
  static bool canRetry(IdentityFailure failure) => switch (failure) {
    ActorDisabled() || MalformedActorId() || MalformedAccessToken() => false,
    InvalidCredentials() ||
    DeviceNotRegistered() ||
    DeviceBindingBroken() ||
    SessionExpired() ||
    NoSession() ||
    IdentityUnavailable() => true,
  };
}
