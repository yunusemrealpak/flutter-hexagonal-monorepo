@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:secure_store/secure_store.dart';

/// A secure storage platform that stores in a map and can be told to throw.
///
/// A behavioural fake rather than a script of expectations: it really stores
/// and really reads back, so the test exercises the adapter's logic instead of
/// asserting that a method was called.
final class FakeSecureStoragePlatform extends FlutterSecureStoragePlatform
    with MockPlatformInterfaceMixin {
  final Map<String, String> entries = {};

  /// Thrown by the next call, whichever it is.
  Object? throwOnNextCall;

  /// The options the adapter passed on the most recent call.
  Map<String, String>? lastOptions;

  void _maybeThrow(Map<String, String> options) {
    lastOptions = options;
    final error = throwOnNextCall;
    if (error != null) {
      throwOnNextCall = null;
      // Typed as Object so that a test can reproduce anything a platform
      // channel is capable of throwing — including something that is neither
      // an Exception nor an Error, which is exactly the case the adapter's
      // `on Object` catch exists for.
      // ignore: only_throw_errors
      throw error;
    }
  }

  @override
  Future<String?> read({
    required String key,
    required Map<String, String> options,
  }) async {
    _maybeThrow(options);
    return entries[key];
  }

  @override
  Future<void> write({
    required String key,
    required String value,
    required Map<String, String> options,
  }) async {
    _maybeThrow(options);
    entries[key] = value;
  }

  @override
  Future<void> delete({
    required String key,
    required Map<String, String> options,
  }) async {
    _maybeThrow(options);
    entries.remove(key);
  }

  @override
  Future<bool> containsKey({
    required String key,
    required Map<String, String> options,
  }) async => entries.containsKey(key);

  @override
  Future<Map<String, String>> readAll({
    required Map<String, String> options,
  }) async => Map.of(entries);

  @override
  Future<void> deleteAll({required Map<String, String> options}) async =>
      entries.clear();
}

void main() {
  const options = {'accessibility': 'first_unlock_this_device'};
  late FakeSecureStoragePlatform platform;
  late KeychainSecureStore store;

  setUp(() {
    platform = FakeSecureStoragePlatform();
    store = KeychainSecureStore(platform, options: options);
  });

  group('KeychainSecureStore', () {
    test('reads back what it wrote', () async {
      await store.write('refresh_token', 'rt-1');

      expect(
        await store.read('refresh_token'),
        const Success<String?, SecureStoreFailure>('rt-1'),
      );
    });

    test('reports a missing key as a successful read of nothing', () async {
      // Matching KeyValueStore: absence is an answer, not an error.
      expect(
        await store.read('never_written'),
        const Success<String?, SecureStoreFailure>(null),
      );
    });

    test('deleting a key that was never written succeeds', () async {
      expect((await store.delete('never_written')).isSuccess, isTrue);
    });

    test('passes the configured options through on every call', () async {
      await store.write('refresh_token', 'rt-1');

      // Accessibility class and backup behaviour are security decisions the
      // composition root makes; an adapter that dropped them would silently
      // store secrets under the platform default.
      expect(platform.lastOptions, options);
    });

    test('turns a dismissed biometric prompt into a failure', () async {
      platform.throwOnNextCall = PlatformException(
        code: 'Unexpected security result code',
        message: 'Code: -128, Message: errSecUserCanceled',
      );

      final result = await store.read('refresh_token');

      expect(
        (result as Failed<String?, SecureStoreFailure>).failure,
        isA<SecureStoreAuthenticationFailed>(),
      );
    });

    test('turns invalidated key material into its own failure', () async {
      platform.throwOnNextCall = PlatformException(
        code: 'Exception encountered',
        message: 'android.security.keystore.KeyPermanentlyInvalidatedException',
      );

      final result = await store.read('refresh_token');

      // The distinction that matters: the credential is gone, so the app has
      // to sign in again. Offering "try again" for a secret that no longer
      // exists is the bug this case prevents.
      expect(
        (result as Failed<String?, SecureStoreFailure>).failure,
        isA<SecureStoreKeyInvalidated>(),
      );
    });

    test('lets no exception escape, whatever the channel throws', () async {
      platform.throwOnNextCall = StateError(
        'something the plugin never promised',
      );

      final result = await store.write('refresh_token', 'rt-1');

      // Invariant 1.2.9: the adapter is the boundary.
      expect(result.isFailure, isTrue);
    });
  });
}
