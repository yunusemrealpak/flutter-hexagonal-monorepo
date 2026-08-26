import 'dart:convert';

import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:payments_api/payments_api.dart';

import 'payments_dto.dart';
import 'payments_mapper.dart';

/// A `PaymentsGateway` that keeps the device's own copy of what it collected.
///
/// **This is the adapter that makes offline idempotency real.**
/// `CollectOnDelivery` asks `attemptFor` before it mints a key, so that two
/// taps on one intention produce one key. Against a bare
/// `RestPaymentsGateway` that check is worthless in a tunnel: the read fails,
/// the use case mints again, and the courier's second tap queues a second
/// collection. With this in front, the read is answered from what this device
/// recorded, and the second tap finds the first.
///
/// It writes locally *after* the remote agrees and *also* when the remote
/// cannot be reached, which is the whole point: the local copy is what the
/// device knows, whether or not anybody else knows it yet. A conflict between
/// the two is not resolved here — that is `ConflictPolicy.manualReview` on the
/// queued entry, and it is a person's decision.
///
/// A decorator rather than a base class. It composes with whatever answers the
/// remote side, so `app_harness` can put a fake behind it and get the same
/// offline behaviour without a second implementation to keep in step.
final class DeviceBackedPaymentsGateway implements PaymentsGateway {
  /// Creates the adapter over [remote] and the device's [store].
  const DeviceBackedPaymentsGateway({
    required this.remote,
    required this.store,
    this.namespace = 'payments.attempt',
  });

  /// What answers when the network does.
  final PaymentsGateway remote;

  /// Where this device's copy is kept.
  final KeyValueStore store;

  /// The key prefix this adapter owns.
  final String namespace;

  @override
  Future<Result<PaymentAttempt, PaymentsFailure>> collect(
    PaymentAttempt attempt,
  ) async {
    final collected = await remote.collect(attempt);

    // A refusal is an answer: nothing was collected, so nothing is written
    // down. Recording it locally would make the next tap find an intention the
    // server has on file as declined.
    if (collected case Failed(failure: CollectionRefused())) return collected;

    // Written after the remote agrees, and *also* when the remote could not be
    // reached — the local copy is what this device knows, whether or not
    // anybody else knows it yet.
    final kept = switch (collected) {
      Success(value: final recorded) => recorded,
      Failed() => attempt,
    };

    return switch (await _remember(kept)) {
      Failed(:final failure) => Failed(failure),
      Success() => Success(kept),
    };
  }

  @override
  Future<Result<PaymentAttempt, PaymentsFailure>> refund(String key) =>
      // Refunds are not written locally on failure. Handing back notes against
      // a record nobody has confirmed is how an operation loses money to a
      // customer who asks twice — the same reason `RefundCollection` has no
      // offline path.
      remote.refund(key);

  @override
  Future<Result<PaymentAttempt?, PaymentsFailure>> attemptFor(
    String shipmentId,
  ) async {
    final remotely = await remote.attemptFor(shipmentId);
    if (remotely case Success(value: final attempt)) {
      if (attempt != null) return Success(attempt);
    }

    // Either the network is gone or the server has nothing. Both are answered
    // from the device, and the second case matters as much as the first: a
    // collection queued this morning is not on the server yet.
    return _recall(shipmentId);
  }

  Future<Result<void, PaymentsFailure>> _remember(
    PaymentAttempt attempt,
  ) async {
    final body = jsonEncode(PaymentsMapper.attemptToDto(attempt).toJson());
    final written = await store.write(
      _keyFor(attempt.request.shipment.value),
      body,
    );

    return switch (written) {
      Failed(:final failure) => Failed(
        PaymentsUnavailable(detail: '$failure'),
      ),
      Success() => const Success(null),
    };
  }

  Future<Result<PaymentAttempt?, PaymentsFailure>> _recall(
    String shipmentId,
  ) async {
    final String? body;
    switch (await store.read(_keyFor(shipmentId))) {
      case Failed(:final failure):
        return Failed(PaymentsUnavailable(detail: '$failure'));
      case Success(:final value):
        body = value;
    }

    if (body == null) return const Success(null);

    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException catch (error) {
      return Failed(
        MalformedPaymentValue(field: 'attempt', reason: error.message),
      );
    }

    if (decoded is! Map<String, dynamic>) {
      return const Failed(
        MalformedPaymentValue(
          field: 'attempt',
          reason: 'the stored record is not a JSON object',
        ),
      );
    }

    return PaymentsMapper.attemptToDomain(
      PaymentAttemptDto.fromJson(decoded),
    ).map((attempt) => attempt);
  }

  String _keyFor(String shipmentId) => '$namespace.$shipmentId';
}
