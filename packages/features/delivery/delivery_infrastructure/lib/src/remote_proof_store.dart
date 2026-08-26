import 'package:core_kernel/core_kernel.dart';
import 'package:delivery_api/delivery_api.dart';
import 'package:http_dio/http_dio.dart';

import 'delivery_dto.dart';
import 'delivery_mapper.dart';

/// Keeps proofs on the operation's server.
///
/// The adapter `app_dispatcher` binds. An operator's machine has no business
/// holding a thousand couriers' photographs, and it always has a connection —
/// so the trade `LocalEncryptedProofStore` makes, durability on the device in
/// exchange for storage, is the wrong one there.
///
/// **The two adapters pass the same contract kit**, and that is what makes the
/// choice a composition-root decision rather than a code change. Nothing in
/// `delivery_application` can tell which of them answered; `CompleteWithProof`
/// stores evidence and gets a handle back either way.
///
/// The reference is whatever the server minted. This adapter does not invent
/// one, does not check its shape and does not parse meaning out of it — which
/// is why `runProofStoreContract` deliberately asserts nothing about the
/// handle's format. A kit that pinned it would fail the day the server changed
/// its identifiers, which is the day it was supposed to be earning its keep.
final class RemoteProofStore implements ProofStorePort {
  /// Creates the adapter over [transport].
  const RemoteProofStore({
    required this.transport,
    this.path = '/delivery/proofs',
  });

  /// The transport the evidence travels on.
  final HttpTransport transport;

  /// Where the proof service lives.
  final String path;

  @override
  Future<Result<ProofReference, DeliveryFailure>> put(
    ProofOfDelivery proof,
  ) async {
    final response = await transport.send(
      HttpRequest(
        method: HttpMethod.post,
        path: path,
        body: DeliveryMapper.proofToDto(proof).toJson(),
      ),
    );

    return switch (response) {
      Failed(:final failure) => Failed(
        ProofStoreUnavailable(detail: '$failure'),
      ),
      Success(value: final ok) => _reference(ok.body),
    };
  }

  @override
  Future<Result<ProofOfDelivery, DeliveryFailure>> read(
    String reference,
  ) async {
    final response = await transport.send(
      HttpRequest(method: HttpMethod.get, path: '$path/$reference'),
    );

    return switch (response) {
      // A rejected read is reported as a missing proof rather than as an
      // unreachable store, because that is what a caller can act on: the
      // reference it holds does not resolve. Distinguishing a 404 from a 500
      // would mean reading a status code here, and the transport already
      // classified the failure once.
      Failed(failure: TransportRejected()) => Failed(ProofNotFound(reference)),
      Failed(:final failure) => Failed(
        ProofStoreUnavailable(detail: '$failure'),
      ),
      Success(value: final ok) => _proof(ok.body),
    };
  }

  Result<ProofReference, DeliveryFailure> _reference(Object? body) {
    if (body is! Map<String, dynamic>) {
      return const Failed(
        MalformedDeliveryValue(
          field: 'body',
          reason: 'the proof service did not answer with a JSON object',
        ),
      );
    }
    return ProofReference.parse(
      ProofReferenceDto.fromJson(body).reference ?? '',
    );
  }

  Result<ProofOfDelivery, DeliveryFailure> _proof(Object? body) {
    if (body is! Map<String, dynamic>) {
      return const Failed(
        MalformedDeliveryValue(
          field: 'body',
          reason: 'the proof service did not answer with a JSON object',
        ),
      );
    }
    return DeliveryMapper.proofToDomain(ProofDto.fromJson(body));
  }
}
