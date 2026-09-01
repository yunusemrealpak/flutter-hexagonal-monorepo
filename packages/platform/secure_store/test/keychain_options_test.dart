@Tags(['unit'])
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secure_store/secure_store.dart';

/// Runs [body] as though the app were on [platform].
///
/// The override is reset afterwards rather than in a `tearDown`, because a
/// leaked target platform makes every later widget test in the same file
/// render for the wrong operating system — a failure that looks like anything
/// except its cause.
T on<T>(TargetPlatform platform, T Function() body) {
  debugDefaultTargetPlatformOverride = platform;
  try {
    return body();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

void main() {
  test('an Apple device is told not to let the credential leave it', () {
    final options = on(TargetPlatform.iOS, () => KeychainOptions.deviceBound);

    // The value that matters, and the one an empty map left unsaid. The
    // plugin's own default accessibility class is decided natively and
    // includes classes that migrate to a new device — for a bearer token tied
    // to a `DeviceBinding`, a copy in somebody's backup is a live credential
    // with nowhere useful to be.
    expect(options['accessibility'], 'first_unlock_this_device');
    expect(options['synchronizable'], 'false');
  });

  test('macOS gets the same policy, because the desk is a device too', () {
    final options = on(TargetPlatform.macOS, () => KeychainOptions.deviceBound);

    expect(options['accessibility'], 'first_unlock_this_device');
  });

  test('Android is told not to wipe the store when it cannot decrypt', () {
    final options = on(
      TargetPlatform.android,
      () => KeychainOptions.deviceBound,
    );

    // `resetOnError` defaults to true, which answers a decryption failure by
    // emptying the store. That turns "the KeyStore is damaged" into "you were
    // never signed in" — collapsing the two failures `IdentityFailure` keeps
    // apart precisely so a caller can route one to sign-in and the other to a
    // retry.
    expect(options['resetOnError'], 'false');
  });

  test('a platform with nothing to decide is left to the plugin', () {
    // Windows and Linux carry no accessibility or backup decision, so a policy
    // here would be an assertion about nothing. Empty is the honest answer,
    // and it is the same one the applications previously gave everywhere.
    expect(
      on(TargetPlatform.windows, () => KeychainOptions.deviceBound),
      isEmpty,
    );
    expect(
      on(TargetPlatform.linux, () => KeychainOptions.deviceBound),
      isEmpty,
    );
  });

  test('the two Apple policies are the same policy', () {
    // A guard against them drifting apart silently: a courier's handset and an
    // operator's desk store the same kind of secret and there is no reason for
    // one to be laxer.
    expect(
      KeychainOptions.apple.params['accessibility'],
      KeychainOptions.mac.params['accessibility'],
    );
  });
}
