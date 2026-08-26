import 'package:core_kernel/core_kernel.dart';
import 'package:http_dio/http_dio.dart';
import 'package:payments_api/payments_api.dart';

import 'payments_dto.dart';
import 'payments_mapper.dart';

/// Answers `PaymentsGateway` from the operation's payments service.
///
/// **The idempotency is carried by the URL.** `collect` is a `PUT` to the
/// attempt's own key rather than a `POST` to a collection, which is what makes
/// a resend after a lost acknowledgement the same request rather than a second
/// charge. An adapter that posted would have to hope the server read a header;
/// this way the shape of the request says it.
///
/// The response is read back rather than the local attempt echoed. The server
/// is the side that decides what was recorded — including answering a retry
/// with the first result — and a gateway that echoed its input would hide a
/// disagreement until a settlement.
///
/// A rejected read is reported as *nothing recorded* rather than as an
/// unreachable service, because that is what a caller can act on: no
/// collection exists against this parcel. Everything else is
/// `PaymentsUnavailable`, and `CollectOnDelivery` is what decides whether that
/// is survivable — cash, yes; card, no.
final class RestPaymentsGateway implements PaymentsGateway {
  /// Creates the adapter over [transport].
  const RestPaymentsGateway({
    required this.transport,
    this.path = '/payments/collections',
  });

  /// The transport the money travels on.
  final HttpTransport transport;

  /// Where the payments service lives.
  final String path;

  @override
  Future<Result<PaymentAttempt, PaymentsFailure>> collect(
    PaymentAttempt attempt,
  ) async {
    final response = await transport.send(
      HttpRequest(
        method: HttpMethod.put,
        path: '$path/${attempt.id.value}',
        body: PaymentsMapper.attemptToDto(attempt).toJson(),
      ),
    );

    return switch (response) {
      // A refusal is an answer the caller has to act on differently from a
      // connection problem, so it is read out of the rejected response rather
      // than flattened into "unavailable".
      Failed(failure: TransportRejected(:final response)) => _refusal(response),
      Failed(:final failure) => Failed(
        PaymentsUnavailable(detail: '$failure'),
      ),
      Success(value: final ok) => _attempt(ok.body),
    };
  }

  @override
  Future<Result<PaymentAttempt, PaymentsFailure>> refund(String key) async {
    final response = await transport.send(
      HttpRequest(method: HttpMethod.post, path: '$path/$key/refund'),
    );

    return switch (response) {
      Failed(failure: TransportRejected()) => Failed(NoCollectionFor(key)),
      Failed(:final failure) => Failed(
        PaymentsUnavailable(detail: '$failure'),
      ),
      Success(value: final ok) => _attempt(ok.body),
    };
  }

  @override
  Future<Result<PaymentAttempt?, PaymentsFailure>> attemptFor(
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
      // Nothing recorded is a successful read of nothing. Most parcels are
      // prepaid, and a failure here would make the ordinary case an error.
      Failed(failure: TransportRejected()) => const Success(null),
      Failed(:final failure) => Failed(
        PaymentsUnavailable(detail: '$failure'),
      ),
      Success(value: final ok) =>
        ok.body == null ? const Success(null) : _attempt(ok.body),
    };
  }

  Result<PaymentAttempt, PaymentsFailure> _attempt(Object? body) {
    if (body is! Map<String, dynamic>) {
      return const Failed(
        MalformedPaymentValue(
          field: 'body',
          reason: 'the payments service did not answer with a JSON object',
        ),
      );
    }
    return PaymentsMapper.attemptToDomain(PaymentAttemptDto.fromJson(body));
  }

  Result<PaymentAttempt, PaymentsFailure> _refusal(HttpResponse response) {
    final body = response.body;
    final reason = body is Map<String, dynamic> ? body['reason'] : null;

    // The far side's own words where it gave any, because a courier standing
    // at a door has to be able to say why: "insufficient funds" and "card
    // expired" send them to different next steps.
    return Failed(
      CollectionRefused(
        reason: reason is String ? reason : 'refused (${response.statusCode})',
      ),
    );
  }
}
