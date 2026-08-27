/// Every string key this package asks an app to answer.
///
/// Declared as constants rather than written inline so that an app can be
/// checked against them: `apps/*/test/catalogue_test.dart` walks [all] for
/// every feature it mounts and fails when a key has no sentence behind it.
abstract final class IdentityStrings {
  /// The sign-in screen's title.
  static const String signInTitle = 'identity.signIn.title';

  /// Shown before anything has been sent.
  static const String signInIdle = 'identity.signIn.idle';

  /// Shown while a sign-in is in flight.
  static const String signInPending = 'identity.signIn.pending';

  /// Shown once somebody is signed in. Takes a `name` argument.
  static const String signedInAs = 'identity.signIn.signedInAs';

  /// The details did not work.
  ///
  /// One key for two failures, and that is a security decision rather than an
  /// oversight — see `SignInScreen.describe`.
  static const String failureRejected = 'identity.failure.rejected';

  /// This device has changed and must be registered again.
  static const String failureDeviceChanged = 'identity.failure.deviceChanged';

  /// The session ended; signing in again is the answer.
  static const String failureSessionEnded = 'identity.failure.sessionEnded';

  /// The account is not active, and nothing on this device will fix that.
  static const String failureDisabled = 'identity.failure.disabled';

  /// Identity could not be reached.
  static const String failureUnavailable = 'identity.failure.unavailable';

  /// Something stored or returned could not be read.
  static const String failureInternal = 'identity.failure.internal';

  /// Every key above, for an app's coverage test.
  static const List<String> all = [
    signInTitle,
    signInIdle,
    signInPending,
    signedInAs,
    failureRejected,
    failureDeviceChanged,
    failureSessionEnded,
    failureDisabled,
    failureUnavailable,
    failureInternal,
  ];
}
