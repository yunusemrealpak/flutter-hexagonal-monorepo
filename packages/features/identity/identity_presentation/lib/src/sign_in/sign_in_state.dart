import 'package:identity_api/identity_api.dart';

/// What the sign-in screen can be showing.
sealed class SignInState {
  const SignInState();
}

/// Waiting for the actor to type.
final class SignInIdle extends SignInState {
  /// Creates the state.
  const SignInIdle();
}

/// The credentials have been sent and no answer has come back.
final class SignInPending extends SignInState {
  /// Creates the state.
  const SignInPending();
}

/// Somebody is signed in.
final class SignedIn extends SignInState {
  /// Creates the state.
  const SignedIn(this.session);

  /// The session that was issued.
  final Session session;
}

/// The attempt failed.
final class SignInRejected extends SignInState {
  /// Creates the state.
  const SignInRejected(this.failure);

  /// Why, in identity's own words.
  ///
  /// A failure rather than a message. What a courier reads is decided at the
  /// widget, where the locale is known, and where a security decision can be
  /// made once: `InvalidCredentials` and `DeviceNotRegistered` deliberately
  /// render the same sentence, because telling somebody which of the two it
  /// was tells an attacker whether the account exists.
  final IdentityFailure failure;
}
