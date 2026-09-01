import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The plugin configuration a session's credentials are stored under.
///
/// `KeychainSecureStore` takes its options as a required constructor argument
/// with no default, and the reason it does is good: accessibility class and
/// backup behaviour are security decisions that belong to an application, and
/// a default here would be the kind nobody revisits. What both applications
/// actually passed was `const {}` — an empty map, which states nothing and
/// leaves every one of those decisions to whatever the native side happens to
/// default to.
///
/// This class is the middle answer. It is not a default: nothing reads it
/// unless a composition root names it. It is a *named policy*, so that an
/// application chooses "device-bound" once, in words, instead of assembling
/// option maps at a call site or — as happened — assembling none.
///
/// ## Why the options are selected by platform here
///
/// `FlutterSecureStoragePlatform` takes one flat map, and the app-facing
/// `FlutterSecureStorage` class is what normally picks the right one per
/// platform. `KeychainSecureStore` is written against the platform interface
/// so that a test can substitute an implementation instead of a method
/// channel, so the selection has to happen somewhere else, and this is it.
/// Merging the maps instead would send Android's keys to the keychain and
/// Apple's to the KeyStore, and each side would silently ignore the other's.
final class KeychainOptions {
  const KeychainOptions._();

  /// The Apple policy: readable after first unlock, never leaves this device.
  ///
  /// `first_unlock_this_device` rather than `unlocked`, and the difference is
  /// the whole point of naming it. Both are readable while the phone is in
  /// use; only this one refuses to migrate to a *new* device. A session here
  /// is tied to a `DeviceBinding` and the server checks the tie, so a token
  /// restored onto a second handset is a token that fails a security check
  /// rather than one that works — but it is also a live bearer token sitting
  /// in somebody's backup until it expires, and there is no reason to put it
  /// there.
  ///
  /// `unlocked_this_device` would be stricter still and is the wrong trade
  /// here: the outbox drains on a connectivity change, which happens while the
  /// screen is off, and a store that refuses to answer then would strand a
  /// courier's queued work until they next picked the phone up.
  ///
  /// iCloud Keychain sync is the other half of the same question, and it is
  /// left unstated because the plugin already answers it: `synchronizable`
  /// defaults to `false`. Passing it explicitly reads as a decision this class
  /// made and would be flagged as a redundant argument — the honest record of
  /// the decision is this paragraph.
  static const IOSOptions apple = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  /// The same policy on macOS, which `app_dispatcher` runs on.
  static const MacOsOptions mac = MacOsOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  /// The Android policy.
  ///
  /// Version 11 of the plugin already encrypts with AES-GCM under a
  /// KeyStore-wrapped key, so the cipher settings are left at their defaults —
  /// there is no weaker legacy mode left to opt out of, and pinning them here
  /// would freeze this package to one plugin release.
  ///
  /// `resetOnError` is the one that has to be stated. Its default is `true`,
  /// which means the plugin answers a decryption failure by **wiping the
  /// store** and carrying on. For a preference that is a reasonable trade; for
  /// a session it turns "the KeyStore is damaged" into "you were never signed
  /// in", which is precisely the distinction `IdentityFailure` separates into
  /// `NoSession` and `IdentityUnavailable` so that a caller can route one to
  /// the sign-in screen and the other to a retry. Set to `false`, the failure
  /// arrives at `KeychainSecureStore`, becomes a `SecureStoreFailure`, and
  /// stays tellable apart all the way up.
  static const AndroidOptions android = AndroidOptions(resetOnError: false);

  /// The policy for the platform this code is running on.
  ///
  /// Anything else — Windows, Linux, the web — gets an empty map, which is the
  /// same "whatever the plugin defaults to" the applications had everywhere.
  /// That is deliberate rather than an omission: those platforms' options
  /// carry no accessibility or backup decision to make, and this workspace
  /// ships no adapter for the web at all.
  static Map<String, String> get deviceBound {
    if (kIsWeb) return const {};
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => apple.params,
      TargetPlatform.macOS => mac.params,
      TargetPlatform.android => android.params,
      _ => const {},
    };
  }
}
