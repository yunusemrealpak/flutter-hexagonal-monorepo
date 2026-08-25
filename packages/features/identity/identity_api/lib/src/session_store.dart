import 'package:core_kernel/core_kernel.dart';

import 'identity_failure.dart';
import 'session.dart';

/// Keeps the session across app launches.
///
/// A driven port over storage, in the product's words rather than a
/// technology's: nothing here mentions a keychain, a preference file or a
/// database. The adapter in `identity_infrastructure` decides that, and
/// decides it once.
///
/// [read] returns `Result<Session?, …>` rather than `Result<Session, …>` with
/// a `NoSession` failure. "There is no stored session" is the ordinary state
/// of a fresh install, not something that went wrong, and making it a failure
/// would put a failure branch on the happy path of every first launch.
abstract interface class SessionStore {
  /// Reads the stored session, or `null` when none is stored.
  Future<Result<Session?, IdentityFailure>> read();

  /// Stores [session], replacing whatever was there.
  Future<Result<void, IdentityFailure>> write(Session session);

  /// Removes the stored session.
  ///
  /// Succeeds when there was nothing to remove, for the same reason
  /// `IdentityFacade.signOut` does.
  Future<Result<void, IdentityFailure>> clear();
}
