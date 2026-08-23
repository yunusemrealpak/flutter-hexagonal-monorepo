@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:core_testing/core_testing.dart';
import 'package:test/test.dart';

void main() {
  group('InMemoryKeyValueStore', () {
    test('reads back what it wrote — it is a fake, not a stub', () async {
      final store = InMemoryKeyValueStore();

      await store.write('cursor', '42');
      final read = await store.read('cursor');

      expect(read, const Success<String?, StoreFailure>('42'));
    });

    test('a missing key is a successful read of nothing', () async {
      final store = InMemoryKeyValueStore();

      final read = await store.read('absent');

      expect(read, const Success<String?, StoreFailure>(null));
    });

    test('deleting a key that does not exist succeeds', () async {
      final store = InMemoryKeyValueStore();

      expect((await store.delete('absent')).isSuccess, isTrue);
    });

    test('reports its keys', () async {
      final store = InMemoryKeyValueStore();
      await store.write('a', '1');
      await store.write('b', '2');

      final keys = await store.keys();

      // Result equality delegates to the wrapped value's ==, and Dart
      // collections compare by identity — so a Result wrapping a collection is
      // unwrapped before being asserted on. See the core_kernel README.
      expect(keys.isSuccess, isTrue);
      expect(keys.fold((value) => value, (failure) => <String>{}), {'a', 'b'});
    });

    test(
      'can be told to fail, which is how failure branches get tested',
      () async {
        final store = InMemoryKeyValueStore()
          ..failNextWith(const StoreOutOfSpace());

        final failed = await store.write('k', 'v');
        final recovered = await store.write('k', 'v');

        expect(failed, const Failed<void, StoreFailure>(StoreOutOfSpace()));
        expect(recovered.isSuccess, isTrue);
        expect(store.entries, {'k': 'v'});
      },
    );

    test('queued failures apply in order, one per call', () async {
      final store = InMemoryKeyValueStore()
        ..failNextWith(const StoreUnavailable())
        ..failNextWith(const StoreCorrupted('k'));

      expect((await store.read('k')).isFailure, isTrue);
      expect((await store.read('k')).isFailure, isTrue);
      expect((await store.read('k')).isSuccess, isTrue);
    });
  });

  group('InMemorySecureStore', () {
    test('stores and clears, so sign-out can be asserted on', () async {
      final store = InMemorySecureStore();

      await store.write('refresh_token', 'abc');
      expect(store.entries, {'refresh_token': 'abc'});

      await store.delete('refresh_token');
      expect(store.entries, isEmpty);
    });

    test('produces failures plain storage has no equivalent for', () async {
      final store = InMemorySecureStore()
        ..failNextWith(const SecureStoreKeyInvalidated());

      final read = await store.read('refresh_token');

      expect(
        read,
        const Failed<String?, SecureStoreFailure>(SecureStoreKeyInvalidated()),
      );
    });
  });
}
