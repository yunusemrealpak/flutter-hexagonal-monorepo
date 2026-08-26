import 'package:delivery_api/delivery_api.dart';
import 'package:test/test.dart';

import 'delivery_fixtures.dart';

/// The behaviour every `ProofStorePort` has to have.
///
/// Run against `FakeProofStore` here, and against both real implementations in
/// `delivery_infrastructure` — the one that encrypts the bytes onto the
/// courier's device and the one that posts them to a server. Three answers,
/// one description: the same shape as `routing`'s optimiser kit, and for the
/// same reason.
///
/// What it asserts is what a caller may rely on: a proof goes in, a handle
/// comes out, and the handle brings the proof back. What it deliberately does
/// *not* assert is anything about the handle's shape. A local store's
/// reference is a row identifier and a remote store's is whatever the server
/// minted; a kit that pinned the format would fail the day the server changed
/// its identifiers, which is the day it was supposed to be earning its keep.
///
/// [createStore] must return a fresh, empty store on every call.
void runProofStoreContract(ProofStorePort Function() createStore) {
  group('ProofStorePort contract', () {
    late ProofStorePort store;

    setUp(() => store = createStore());

    Future<ProofReference> put(ProofOfDelivery proof) async =>
        (await store.put(proof)).fold(
          (reference) => reference,
          (failure) => throw StateError('$failure'),
        );

    test('reads back what was written', () async {
      final proof = DeliveryFixtures.fullProof();

      final reference = await put(proof);
      final read = await store.read(reference.value);

      final stored = read.fold((p) => p, (f) => throw StateError('$f'));
      expect(stored.carries, proof.carries);
      expect(stored.recipient, proof.recipient);
    });

    test('keeps the bytes, not just the fact that there were some', () async {
      // The assertion that catches a store which records "a signature was
      // taken" and drops the image. Months later, that difference is the whole
      // value of the record.
      final proof = DeliveryFixtures.proof(
        signature: DeliveryFixtures.signature(bytes: const [9, 8, 7, 6]),
      );

      final reference = await put(proof);
      final read = await store.read(reference.value);

      expect(
        read.fold((p) => p.signature!.bytes, (f) => throw StateError('$f')),
        [9, 8, 7, 6],
      );
    });

    test('two proofs get two references', () async {
      // A store that reused a handle would overwrite one delivery's evidence
      // with another's, and the loss would be silent.
      final first = await put(DeliveryFixtures.proof());
      final second = await put(
        DeliveryFixtures.proof(photo: DeliveryFixtures.photo()),
      );

      expect(first.value, isNot(second.value));
    });

    test('reports a reference it does not hold', () async {
      final read = await store.read('nothing-was-stored-here');

      expect(
        read.fold((_) => null, (failure) => failure),
        isA<ProofNotFound>(),
      );
    });

    test('keeps the recipient a hand-over was signed for', () async {
      // The name is the part a dispute turns on: a neighbour who signed is a
      // different fact from the consignee who did.
      final proof = ProofOfDelivery.captured(
        recipient: DeliveryFixtures.recipient(
          name: 'B. Kaya',
          relationship: 'neighbour',
        ),
        capturedAt: DeliveryFixtures.noon,
        signature: DeliveryFixtures.signature(),
      );

      final reference = await put(proof);
      final read = await store.read(reference.value);

      final stored = read.fold((p) => p, (f) => throw StateError('$f'));
      expect(stored.recipient.name, 'B. Kaya');
      expect(stored.recipient.relationship, 'neighbour');
    });
  });
}
