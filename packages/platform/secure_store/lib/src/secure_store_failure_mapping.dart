import 'package:core_ports/core_ports.dart';
import 'package:flutter/services.dart';

// The signals each failure is recognised by.
//
// This is the least satisfying code in the package and the comment is here so
// that nobody mistakes it for craft. Platform channels report failure as a
// `PlatformException` whose `code` and `message` are strings the plugin's
// native side composed; there is no enumeration to switch on. Matching on
// substrings is what is available, and it is brittle by nature: a plugin
// upgrade can reword a message and silently move a failure into the catch-all.
//
// Two things keep the brittleness bounded. The catch-all is
// `SecureStoreUnavailable`, which is the answer a caller can retry, so a
// missed signal degrades rather than misleads. And the lists are here, named,
// in one file — so when a message does change, there is one place to correct
// and one test to update.

/// Fragments that mean the stored value can no longer be decrypted.
const _invalidationSignals = <String>[
  // Android: the user changed the device passcode or re-enrolled biometrics,
  // which invalidates the key the value was encrypted with.
  'KeyPermanentlyInvalidatedException',
  'BadPaddingException',
  'AEADBadTagException',
  // Darwin: a restored backup or a reinstall leaves an item whose key material
  // is gone.
  'errSecDecode',
];

/// Fragments that mean the platform demanded authentication and did not get it.
const _authenticationSignals = <String>[
  // Darwin: the biometric or passcode prompt was dismissed, failed, or the
  // device is locked and the item is not readable while it is.
  'errSecAuthFailed',
  'errSecUserCanceled',
  'errSecInteractionNotAllowed',
  '-25293',
  '-128',
  '-25308',
  // Android: BiometricPrompt reported a cancellation.
  'UserCanceled',
  'AuthenticationFailed',
];

/// Translates what a platform channel threw into the `sealed` failure the
/// `SecureStore` port declares.
///
/// Three cases are distinguished because a caller behaves differently about
/// each: an unavailable store is worth retrying, a failed authentication is
/// worth asking the user about, and an invalidated key means the credential is
/// gone and the only way forward is to sign in again. Collapsing the last two
/// produces an app that offers "try again" for a secret that no longer exists.
///
/// Anything unrecognised becomes [SecureStoreUnavailable] — the retryable
/// answer — so that a reworded platform message degrades the diagnosis instead
/// of inverting it.
SecureStoreFailure secureStoreFailureFrom(Object error) {
  if (error is MissingPluginException) {
    // No implementation registered for this platform. Common on desktop and in
    // a widget test that forgot to install one, and never transient.
    return const SecureStoreUnavailable();
  }
  if (error is PlatformException) {
    final signal =
        '${error.code} ${error.message ?? ''} ${error.details ?? ''}';
    if (_invalidationSignals.any(signal.contains)) {
      return const SecureStoreKeyInvalidated();
    }
    if (_authenticationSignals.any(signal.contains)) {
      return const SecureStoreAuthenticationFailed();
    }
  }
  return const SecureStoreUnavailable();
}
