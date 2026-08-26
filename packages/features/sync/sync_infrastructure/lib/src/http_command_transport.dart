import 'package:core_kernel/core_kernel.dart';
import 'package:http_dio/http_dio.dart';
import 'package:sync_api/sync_api.dart';

import 'sync_envelope_dto.dart';
import 'sync_envelope_mapper.dart';

/// Answers `CommandTransportPort` over the operation's HTTP API.
///
/// Everything protocol-shaped stops here. The drain above it handed over an
/// envelope; this class decides that the question is a `POST /sync/commands`,
/// that a 409 means the server has moved on, that a 4xx is permanent and a 5xx
/// is not, and that the body has to go through a DTO before anything upstairs
/// sees it.
///
/// **The translation table is the point of the class.** It is the only place
/// in the feature where a status code exists, and it is what lets
/// `DrainOutbox` — which decides whether to retry, block or drop — do so
/// without knowing that HTTP is involved. Move any row of it upwards and the
/// retry policy stops compiling the day the API becomes gRPC.
///
/// | What came back | What the queue is told | What the drain does |
/// |---|---|---|
/// | offline / DNS / refused | `SyncOffline` | stop, count no attempt |
/// | timeout, 5xx | `SyncTransportFailed` | back off and retry |
/// | 409, or a 2xx saying `conflict` | `SyncConflict` | ask the policy |
/// | any other 4xx | `SyncRejected` | block for a person |
///
/// It takes an `HttpTransport` rather than a `Dio`. That contract lives in
/// `platform/http_dio` together with its adapter and its fake, so this class
/// never opens a socket in a test and the day Dio is replaced, one file in one
/// platform package changes.
final class HttpCommandTransport implements CommandTransportPort {
  /// Creates the adapter over [transport].
  const HttpCommandTransport({
    required this.transport,
    this.path = '/sync/commands',
  });

  /// The transport envelopes are sent on.
  final HttpTransport transport;

  /// Where the server accepts commands.
  final String path;

  @override
  Future<Result<SyncCursor, SyncFailure>> send(SyncEnvelope envelope) async {
    final response = await transport.send(
      HttpRequest(
        method: HttpMethod.post,
        path: path,
        body: SyncEnvelopeMapper.toDto(envelope).toJson(),
        // The identifier goes in a header as well as in the body, because that
        // is where a server's idempotency middleware looks for it — usually
        // before anything has parsed the body at all.
        headers: {'Idempotency-Key': envelope.id.value},
      ),
    );

    return switch (response) {
      Failed(:final failure) => Failed(_translate(failure)),
      Success(value: final ok) => _readAck(ok.body),
    };
  }

  /// Reads the acknowledgement, including the conflict a 2xx can carry.
  Result<SyncCursor, SyncFailure> _readAck(Object? body) {
    final json = body;
    if (json is! Map<String, dynamic>) {
      return const Failed(
        MalformedEntry(field: 'body', reason: 'is not a JSON object'),
      );
    }

    final ack = SyncAckDto.fromJson(json);
    final cursor = ack.cursor;

    if (ack.conflict ?? false) {
      // A success status that says "you were working against an old position".
      // Treating it as an acceptance would drop the entry and lose the write,
      // which is the most expensive mistake available in this file.
      return Failed(
        SyncConflict(
          cursor: cursor ?? '',
          detail: ack.reason ?? 'the server has moved on',
        ),
      );
    }

    if (cursor == null) {
      return const Failed(
        MalformedEntry(field: 'cursor', reason: 'is missing'),
      );
    }
    return Success(SyncCursor(cursor));
  }

  /// Turns a transport failure into the vocabulary the port promises.
  ///
  /// This is why the two failure hierarchies are separate. `DrainOutbox`
  /// handles `SyncFailure` and must never see a `TransportRejected`: a status
  /// code is a fact about HTTP, and a retry policy that switched on one would
  /// be a retry policy that stops compiling when the API moves to gRPC.
  static SyncFailure _translate(TransportFailure failure) => switch (failure) {
    // The detail is dropped rather than carried. `SyncOffline` is the one
    // failure the drain acts on structurally — it stops without counting an
    // attempt — and a message on it would only ever end up in a log that
    // already says the device was offline.
    TransportOffline() => const SyncOffline(),
    TransportTimeout(:final phase) => SyncTransportFailed(
      detail: 'timed out while ${phase.name}ing',
    ),
    TransportRejected(statusCode: 409, :final response) => SyncConflict(
      cursor: _cursorIn(response),
      detail: 'the server has moved on',
    ),
    // 5xx is the server having a bad minute; 4xx is this command being wrong.
    // The split is what stops a deploy turning a fleet's queues into a review
    // backlog, and what stops a malformed command being retried forever.
    TransportRejected(:final statusCode) when statusCode >= 500 =>
      SyncTransportFailed(detail: 'rejected with $statusCode'),
    TransportRejected(:final statusCode) => SyncRejected(
      reason: 'rejected with $statusCode',
      statusCode: statusCode,
    ),
    TransportCancelled() => const SyncTransportFailed(detail: 'cancelled'),
    TransportCertificateRejected() => const SyncTransportFailed(
      detail: 'certificate rejected',
    ),
    TransportUnexpected(:final detail) => SyncTransportFailed(detail: detail),
  };

  static String _cursorIn(HttpResponse response) {
    final body = response.body;
    if (body is! Map<String, dynamic>) return '';
    return SyncAckDto.fromJson(body).cursor ?? '';
  }
}
