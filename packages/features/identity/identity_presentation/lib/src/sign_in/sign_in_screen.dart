import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:identity_api/identity_api.dart';

import '../identity_strings.dart';
import 'sign_in_bloc.dart';
import 'sign_in_event.dart';
import 'sign_in_state.dart';

/// The sign-in screen.
///
/// The bloc arrives through the widget tree rather than the constructor.
/// `BlocProvider` is an `InheritedWidget` scoped to a subtree, not a service
/// locator, so invariant 1.2.7 is satisfied for the same reason
/// `PeykStrings.of(context)` satisfies it two lines below.
final class SignInScreen extends StatelessWidget {
  /// Creates the screen.
  ///
  /// Whoever mounts it puts a [SignInBloc] above it with `BlocProvider`.
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = PeykStrings.of(context);

    return PeykScreen(
      title: strings.resolve(IdentityStrings.signInTitle),
      // No `buildWhen` here, and that is a decision rather than an omission.
      // Every transition this bloc can make changes the state's case —
      // pending, signed in, rejected — so narrowing on the case would skip
      // nothing, and narrowing further would have to know which failure is on
      // screen. `buildWhen` pays where a `BlocSelector` sits under it, which
      // is `CollectionScreen`'s shape and not this one's.
      body: BlocBuilder<SignInBloc, SignInState>(
        builder: (context, state) => Center(
          child: switch (state) {
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
              onRetry: canRetry(failure)
                  ? () => context.read<SignInBloc>().add(const SignInCleared())
                  : null,
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
