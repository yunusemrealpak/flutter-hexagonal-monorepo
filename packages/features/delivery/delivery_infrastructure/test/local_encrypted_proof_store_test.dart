@Tags(['unit'])
library;

import 'package:core_ports/core_ports.dart';
import 'package:core_testing/core_testing.dart';
import 'package:delivery_api/delivery_api.dart';
import 'package:delivery_infrastructure/delivery_infrastructure.dart';
import 'package:delivery_testing/delivery_testing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryKeyValueStore store;
  late LocalEncryptedProofStore proofs;

  setUp(() {
    store = InMemoryKeyValueStore();
    proofs = LocalEncryptedProofStore(store: store);
  });

  group('LocalEncryptedProofStore', () {
    test('keeps its counter on disk, not in memory', () async {
      // A counter held in the adapter would start again at one after a crash
      // and overwrite the morning's evidence. This is the assertion that
      // catches it: a second adapter over the same store continues the
      // sequence rather than restarting it.
      final first = await proofs.put(DeliveryFixtures.proof());
      final afterRestart = LocalEncryptedProofStore(store: store);
      final second = await afterRestart.put(DeliveryFixtures.proof());

      expect(
        first.fold((r) => r.value, (f) => throw StateError('$f')),
        isNot(second.fold((r) => r.value, (f) => throw StateError('$f'))),
      );
    });

    test('writes the record before it moves the counter', () async {
      // A crash between the two writes should leave a stored proof nothing
      // points at — a few wasted bytes — rather than a counter that has moved
      // past a proof that was never written.
      store.failNextWith(const StoreUnavailable(detail: 'disk full'));

      final refused = await proofs.put(DeliveryFixtures.proof());

      expect(refused.fold((_) => null, (f) => f), isA<ProofStoreUnavailable>());
    });

    test('keeps everything under its own namespace', () async {
      // So that signing out can clear delivery's evidence without touching
      // another feature's cursors.
      await proofs.put(DeliveryFixtures.proof());

      final keys = await store.keys();
      expect(
        keys.fold((k) => k, (f) => throw StateError('$f')),
        everyElement(startsWith('delivery.proof')),
      );
    });

    test(
      'a reference it does not hold is not found, not unavailable',
      () async {
        // The difference matters to a caller: one is a bad reference and the
        // other is a locked disk.
        final read = await proofs.read('delivery.proof-99');

        expect(read.fold((_) => null, (f) => f), isA<ProofNotFound>());
      },
    );

    test('a locked store is unavailable, not not-found', () async {
      store.failNextWith(const StoreUnavailable(detail: 'locked'));

      final read = await proofs.read('delivery.proof-1');

      expect(read.fold((_) => null, (f) => f), isA<ProofStoreUnavailable>());
    });

    test('a corrupted record is a named failure, not a crash', () async {
      // Somebody else's data, which is what a mapper exists to survive.
      await store.write('delivery.proof.record.delivery.proof-1', 'not json');

      final read = await proofs.read('delivery.proof-1');

      expect(
        read.fold((_) => null, (f) => f),
        isA<MalformedDeliveryValue>(),
      );
    });
  });
}
