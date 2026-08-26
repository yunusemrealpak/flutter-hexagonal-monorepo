import 'package:core_kernel/core_kernel.dart';
import 'package:http_dio/http_dio.dart';
import 'package:messaging_api/messaging_api.dart';

/// Carries a message to the operation over HTTP.
///
/// The translation that matters here is the failure one, and it is the reason
/// `MessagingFailure` has two transport cases instead of one:
///
/// | What came back | What this feature calls it | What happens next |
/// |---|---|---|
/// | offline, timeout, cancelled | `DeliveryDeferred` | it stays queued |
/// | 4xx | `DeliveryRefused` | it stops being retried |
/// | 5xx, certificate, unexpected | `DeliveryDeferred` | it stays queued |
///
/// A 4xx is the server saying this will never work — a closed thread, a
/// courier taken off the round — and retrying it for ever is how an outbox
/// fills with work nobody will accept. A 5xx is the server having a bad
/// afternoon. An adapter that collapsed the two would pick one of those two
/// failure modes, and both are bad in a way somebody notices weeks later.
final class HttpMessageTransport implements MessageTransport {
  /// Creates the adapter over the transport it sends through.
  const HttpMessageTransport({required this._transport});

  final HttpTransport _transport;

  @override
  Future<Result<DateTime, MessagingFailure>> send(Message message) async {
    final response = await _transport.send(
      HttpRequest(
        method: HttpMethod.post,
        path: '/threads/${message.thread.value}/messages',
        body: {
          'id': message.id.value,
          'author': message.author.value,
          'body': message.body,
          'writtenAt': message.writtenAt.toIso8601String(),
        },
      ),
    );

    return switch (response) {
      Failed(:final failure) => Failed(_translate(failure)),
      Success(:final value) => _acceptedAt(value),
    };
  }

  @override
  Future<Result<void, MessagingFailure>> acknowledgeRead(
    Message message,
  ) async {
    final response = await _transport.send(
      HttpRequest(
        method: HttpMethod.post,
        path: '/threads/${message.thread.value}/read',
        body: {'through': message.id.value},
      ),
    );

    return switch (response) {
      Failed(:final failure) => Failed(_translate(failure)),
      Success() => const Success(null),
    };
  }

  /// Reads the instant the server says it took the message.
  ///
  /// The server's instant, not the device's: two phones in different time
  /// zones with drifting clocks would otherwise each stamp their own, and one
  /// thread would sort differently on each of them. A response that does not
  /// carry one is deferred rather than accepted — a message this device
  /// believes was sent, with no agreed instant on it, is a message that will
  /// sort wrongly for ever.
  Result<DateTime, MessagingFailure> _acceptedAt(HttpResponse response) {
    final body = response.body;
    final raw = body is Map<String, Object?> ? body['acceptedAt'] : null;
    final instant = raw is String ? DateTime.tryParse(raw) : null;

    return instant == null
        ? const Failed(
            DeliveryDeferred(detail: 'the server did not say when it took it'),
          )
        : Success(instant.toUtc());
  }

  MessagingFailure _translate(TransportFailure failure) => switch (failure) {
    TransportRejected(:final statusCode) when statusCode < 500 =>
      DeliveryRefused(reason: 'the operation refused it ($statusCode)'),
    TransportRejected(:final statusCode) => DeliveryDeferred(
      detail: 'the server failed ($statusCode)',
    ),
    TransportOffline() ||
    TransportTimeout() ||
    TransportCancelled() ||
    TransportCertificateRejected() ||
    TransportUnexpected() => DeliveryDeferred(detail: failure.toString()),
  };
}
