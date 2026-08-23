@Tags(['unit'])
library;

import 'package:core_ports/core_ports.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secure_store/secure_store.dart';

void main() {
  group('secureStoreFailureFrom', () {
    test('maps a missing plugin implementation to unavailable', () {
      expect(
        secureStoreFailureFrom(MissingPluginException('no implementation')),
        isA<SecureStoreUnavailable>(),
      );
    });

    test('recognises each invalidation signal', () {
      for (final message in const [
        'android.security.keystore.KeyPermanentlyInvalidatedException',
        'javax.crypto.BadPaddingException',
        'javax.crypto.AEADBadTagException',
        'Code: -26275, Message: errSecDecode',
      ]) {
        expect(
          secureStoreFailureFrom(
            PlatformException(code: 'x', message: message),
          ),
          isA<SecureStoreKeyInvalidated>(),
          reason: message,
        );
      }
    });

    test('recognises each authentication signal', () {
      for (final message in const [
        'Code: -128, Message: errSecUserCanceled',
        'Code: -25293, Message: errSecAuthFailed',
        'Code: -25308, Message: errSecInteractionNotAllowed',
        'AuthenticationFailed',
      ]) {
        expect(
          secureStoreFailureFrom(
            PlatformException(code: 'x', message: message),
          ),
          isA<SecureStoreAuthenticationFailed>(),
          reason: message,
        );
      }
    });

    test('reads the details field as well as the message', () {
      // Plugins are inconsistent about which field carries the native error.
      expect(
        secureStoreFailureFrom(
          PlatformException(code: 'x', details: 'errSecAuthFailed'),
        ),
        isA<SecureStoreAuthenticationFailed>(),
      );
    });

    test('falls back to the retryable case for anything unrecognised', () {
      // The catch-all is deliberately the answer a caller can retry, so a
      // reworded platform message degrades the diagnosis instead of inverting
      // it into "your credential is gone".
      expect(
        secureStoreFailureFrom(
          PlatformException(code: 'x', message: 'something new in v12'),
        ),
        isA<SecureStoreUnavailable>(),
      );
      expect(
        secureStoreFailureFrom(StateError('nope')),
        isA<SecureStoreUnavailable>(),
      );
    });
  });
}
