import 'package:core_kernel/core_kernel.dart';
import 'package:delivery_api/delivery_api.dart';
import 'package:http_dio/http_dio.dart';

import 'delivery_dto.dart';
import 'delivery_mapper.dart';

/// Answers `DeliveryGateway` from the operation's delivery service.
///
/// **Nothing in `delivery_application` calls `submit`.** A courier who has
/// just handed over a parcel is not made to wait for a server, so
/// `CompleteWithProof` queues a `CompleteDeliveryCommand` and returns; what
/// eventually calls this is the transport handler an app registered for that
/// routing key. The port lives in `delivery_api` because the *contract* — what
/// an attempt looks like on the wire — is delivery's word; when to call it is
/// the queue's business.
///
/// Which is why the retry policy is not here either. A queued entry is retried
/// by `sync`, on a schedule that knows how many times it has already tried;
/// an adapter that retried on its own would multiply the two.
final class RestDeliveryGateway implements DeliveryGateway {
  /// Creates the adapter over [transport].
  const RestDeliveryGateway({
    required this.transport,
    this.path = '/delivery/attempts',
  });

  /// The transport the record travels on.
  final HttpTransport transport;

  /// Where the delivery service lives.
  final String path;

  @override
  Future<Result<DeliveryAttempt, DeliveryFailure>> submit(
    DeliveryAttempt attempt,
  ) async {
    final response = await transport.send(
      HttpRequest(
        method: HttpMethod.put,
        // PUT to the attempt's own identifier rather than POST to a
        // collection. The identifier was minted on the device when the courier
        // arrived, and a resend after a lost acknowledgement has to be the
        // same request rather than a second delivery.
        path: '$path/${attempt.id.value}',
        body: DeliveryMapper.attemptToDto(attempt).toJson(),
      ),
    );

    return switch (response) {
      Failed(:final failure) => Failed(DeliveryUnavailable(detail: '$failure')),
      // The server's copy is read back rather than the local one returned. It
      // is the side that decides what was recorded, and a gateway that echoed
      // its input would hide a server that stored something else.
      Success(value: final ok) => _attempt(ok.body),
    };
  }

  @override
  Future<Result<List<DeliveryAttempt>, DeliveryFailure>> attemptsFor(
    String shipmentId,
  ) async {
    final response = await transport.send(
      HttpRequest(
        method: HttpMethod.get,
        path: path,
        query: {'shipmentId': shipmentId},
      ),
    );

    return switch (response) {
      Failed(:final failure) => Failed(DeliveryUnavailable(detail: '$failure')),
      Success(value: final ok) => _attempts(ok.body),
    };
  }

  Result<DeliveryAttempt, DeliveryFailure> _attempt(Object? body) {
    if (body is! Map<String, dynamic>) {
      return const Failed(
        MalformedDeliveryValue(
          field: 'body',
          reason: 'the delivery service did not answer with a JSON object',
        ),
      );
    }
    return DeliveryMapper.attemptToDomain(DeliveryAttemptDto.fromJson(body));
  }

  Result<List<DeliveryAttempt>, DeliveryFailure> _attempts(Object? body) {
    if (body is! List) {
      return const Failed(
        MalformedDeliveryValue(
          field: 'body',
          reason: 'the delivery service did not answer with a JSON array',
        ),
      );
    }

    final attempts = <DeliveryAttempt>[];
    for (final row in body) {
      if (row is! Map<String, dynamic>) {
        return const Failed(
          MalformedDeliveryValue(
            field: 'body[]',
            reason: 'a row is not a JSON object',
          ),
        );
      }

      // One bad row fails the whole read. A gateway that skipped it would
      // answer "two visits" to a question whose true answer is three, and
      // nothing downstream could tell the difference.
      switch (DeliveryMapper.attemptToDomain(
        DeliveryAttemptDto.fromJson(row),
      )) {
        case Failed(:final failure):
          return Failed(failure);
        case Success(:final value):
          attempts.add(value);
      }
    }

    return Success(List.unmodifiable(attempts));
  }
}
