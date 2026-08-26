import 'dart:convert';

import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:delivery_api/delivery_api.dart';

import 'delivery_dto.dart';
import 'delivery_mapper.dart';

/// Keeps proofs on the courier's own device.
///
/// The adapter `app_courier` binds. A signature captured in a basement has to
/// be kept somewhere before it can be sent, and "somewhere" on a phone that
/// may not see a network until the evening is the device itself.
///
/// **Where the "encrypted" in the name comes from.** Not from this file:
/// there is no cipher here, and inventing one would be worse than not having
/// one. The `KeyValueStore` a composition root binds under it is drift-backed,
/// and the database is opened with a passphrase the app reads from
/// `SecureStore` — which is exactly what `SecureStore`'s own documentation
/// reserves it for, secrets rather than payloads. Encryption at rest is a
/// property of the store beneath this adapter, and putting it here would mean
/// every adapter that persists anything re-implementing it.
///
/// **`KeyValueStore` rather than a repository of its own.** That port's
/// documentation warns against persisting domain data through it, and the
/// warning is about features that skip designing a repository. This is the
/// repository: `ProofStorePort` is delivery's own outbound port, typed and
/// versioned, and the key-value store is the byte bucket underneath it.
/// `routing`'s cache is built the same way, for the same reason.
///
/// References are minted from the attempt-scoped counter the store already
/// keeps, not from `Random` or `Uuid` — rules A2 and A3 apply here as they do
/// everywhere outside `apps/`. The sequence number is read back from the store
/// so that it survives a restart; a counter held in memory would start again
/// at one after a crash and overwrite the morning's evidence.
final class LocalEncryptedProofStore implements ProofStorePort {
  /// Creates the adapter over [store].
  const LocalEncryptedProofStore({
    required this.store,
    this.namespace = 'delivery.proof',
  });

  /// Where the records go.
  final KeyValueStore store;

  /// The key prefix this adapter owns.
  ///
  /// Everything it writes starts with this, so that signing out can clear
  /// delivery's evidence without touching another feature's cursors.
  final String namespace;

  @override
  Future<Result<ProofReference, DeliveryFailure>> put(
    ProofOfDelivery proof,
  ) async {
    final int next;
    switch (await store.read('$namespace.sequence')) {
      case Failed(:final failure):
        return Failed(ProofStoreUnavailable(detail: '$failure'));
      case Success(:final value):
        next = (int.tryParse(value ?? '0') ?? 0) + 1;
    }

    final raw = '$namespace-$next';
    final body = jsonEncode(DeliveryMapper.proofToDto(proof).toJson());

    // The record before the counter. A crash between the two writes leaves a
    // stored proof that nothing points at, which costs a few bytes; the other
    // order leaves a counter that has moved past a proof that was never
    // written, and the next hand-over overwrites nothing that exists.
    switch (await store.write(_keyFor(raw), body)) {
      case Failed(:final failure):
        return Failed(ProofStoreUnavailable(detail: '$failure'));
      case Success():
        break;
    }

    switch (await store.write('$namespace.sequence', '$next')) {
      case Failed(:final failure):
        return Failed(ProofStoreUnavailable(detail: '$failure'));
      case Success():
        return ProofReference.parse(raw);
    }
  }

  @override
  Future<Result<ProofOfDelivery, DeliveryFailure>> read(
    String reference,
  ) async {
    final String? body;
    switch (await store.read(_keyFor(reference))) {
      case Failed(:final failure):
        return Failed(ProofStoreUnavailable(detail: '$failure'));
      case Success(:final value):
        body = value;
    }

    // A missing key is a successful read of nothing — that is the store's
    // contract — and it is this port's `ProofNotFound` rather than a storage
    // failure. The difference matters to a caller: one is a bad reference and
    // the other is a locked disk.
    if (body == null) return Failed(ProofNotFound(reference));

    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException catch (error) {
      return Failed(
        MalformedDeliveryValue(field: 'proof', reason: error.message),
      );
    }

    if (decoded is! Map<String, dynamic>) {
      return const Failed(
        MalformedDeliveryValue(
          field: 'proof',
          reason: 'the stored record is not a JSON object',
        ),
      );
    }

    return DeliveryMapper.proofToDomain(ProofDto.fromJson(decoded));
  }

  String _keyFor(String reference) => '$namespace.record.$reference';
}
