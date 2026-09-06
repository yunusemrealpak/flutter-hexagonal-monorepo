import 'package:identity_api/identity_api.dart';

/// What can be asked of the sign-in screen.
///
/// Two cases, and the first one is the reason this is a `Bloc` rather than a
/// `Cubit`: [CredentialsSubmitted] is registered with `droppable()`, and a
/// method call has nowhere to carry a concurrency policy.
sealed class SignInEvent {
  const SignInEvent();
}

/// Send [credentials].
final class CredentialsSubmitted extends SignInEvent {
  /// Creates the event.
  const CredentialsSubmitted(this.credentials);

  /// What is being offered, in whatever kind this app signs in with.
  ///
  /// The bloc never builds these. A bloc that constructed
  /// `PasswordCredentials` itself would be a bloc `app_dispatcher` cannot use,
  /// because a desk signs in through a corporate provider.
  final Credentials credentials;
}

/// Return the screen to its starting state.
///
/// What the retry on a rejected sign-in does. There is nothing to re-send: no
/// part of this package holds the credentials it was given, deliberately — a
/// screen that kept them would keep a password in memory for as long as it is
/// on the stack. Trying again therefore means asking again.
final class SignInCleared extends SignInEvent {
  /// Creates the event.
  const SignInCleared();
}
