import 'package:core_kernel/core_kernel.dart';

import 'credentials.dart';
import 'identity_failure.dart';
import 'session.dart';

/// What the rest of the product asks identity to *do*.
///
/// The driving port: presentation packages and app composition roots call it,
/// `identity_application` implements it. It is declared here rather than in
/// `identity_application` for the reason every port is declared in an `_api`
/// package — a caller that depended on the implementation to get the interface
/// would be depending on the implementation.
///
/// Every method returns a `Result` because every one of them talks to a store
/// or a server. [sessionChanges] does not, because a stream that has already
/// been opened cannot fail to be read; anything that goes wrong while
/// producing it is reported through the method that caused it.
abstract interface class IdentityFacade {
  /// Exchanges [credentials] for a session on this device.
  Future<Result<Session, IdentityFailure>> signIn(Credentials credentials);

  /// Ends the current session, locally and remotely.
  ///
  /// Succeeds when there is no session to end. Sign-out is the one operation a
  /// user reaches for when something is already wrong, and failing it because
  /// there was nothing to do would strand them on a screen they are trying to
  /// leave.
  Future<Result<void, IdentityFailure>> signOut();

  /// Exchanges the current session's refresh window for a fresh token.
  Future<Result<Session, IdentityFailure>> refreshSession();

  /// Emits the current session whenever it changes, and `null` after sign-out.
  ///
  /// This is what a router listens to. `null` rather than an absent event, so
  /// that "signed out" is a value a `StreamBuilder` can render rather than a
  /// silence it has to time out on.
  Stream<Session?> sessionChanges();
}
