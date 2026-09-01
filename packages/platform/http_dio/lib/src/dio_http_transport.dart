import 'package:core_kernel/core_kernel.dart';
import 'package:dio/dio.dart';
import 'http_request.dart';
import 'http_response.dart';
import 'http_transport.dart';
import 'transport_failure.dart';

/// The [HttpTransport] the shipped applications run on.
///
/// This package is the only one in the workspace that imports Dio, and that is
/// the whole point of it: base URL, timeouts, interceptors and certificate
/// pinning are configured on the [Dio] instance handed to the constructor, so
/// the composition root owns the environment and no caller can accidentally
/// address a different one. `PeykTransport` is where the applications get
/// those settings from, and the interceptors beside this file are what turn
/// them into behaviour.
///
/// **`validateStatus: (_) => true` below has a consequence worth carrying into
/// those files.** No status ever becomes a `DioException`, so an interceptor
/// that wants to act on a 401 or a 503 has to do it in `onResponse`; `onError`
/// sees only a connection that broke or a clock that ran out.
///
/// Its real work is the translation in [_mapException]. Dio reports failure by
/// throwing, and an exception that escaped here would cross a port boundary —
/// invariant 1.2.9 — so every throwing path ends in a `Failed`.
final class DioHttpTransport implements HttpTransport {
  /// Sends through the `Dio` instance handed in, which carries the base URL
  /// and any interceptors the composition root configured.
  const DioHttpTransport(this._dio);

  final Dio _dio;

  @override
  Future<Result<HttpResponse, TransportFailure>> send(
    HttpRequest request,
  ) async {
    try {
      final response = await _dio.request<Object?>(
        request.path,
        queryParameters: request.query,
        data: request.body,
        options: Options(
          method: request.method.name.toUpperCase(),
          headers: request.headers,
          // Dio's default is to throw for a non-2xx status. Letting every
          // status through and classifying it here keeps the decision in one
          // place, and keeps the response body of a 4xx — which is where an
          // API puts the reason — reachable by the caller.
          validateStatus: (_) => true,
        ),
      );
      return _classify(response);
    } on DioException catch (error) {
      return Failed(_mapException(error));
    } on Object catch (error) {
      // Nothing is expected to reach here; the branch exists so that a
      // surprise from a Dio upgrade becomes a failure the caller handles
      // rather than an exception that escapes the adapter.
      return Failed(TransportUnexpected(detail: error.toString()));
    }
  }

  Result<HttpResponse, TransportFailure> _classify(Response<Object?> response) {
    final translated = _toResponse(response);
    final status = translated.statusCode;
    if (status >= 200 && status < 300) {
      return Success(translated);
    }
    return Failed(TransportRejected(translated));
  }

  HttpResponse _toResponse(Response<Object?> response) => HttpResponse(
    // Dio types the status as nullable because a response can be synthesised
    // by an interceptor. Nothing usable came back without one, so 0 stands for
    // "no status", and 0 is not in the 2xx range that means success.
    statusCode: response.statusCode ?? 0,
    body: response.data,
    headers: Map.unmodifiable(response.headers.map),
  );

  TransportFailure _mapException(DioException error) => switch (error.type) {
    DioExceptionType.connectionTimeout => const TransportTimeout(
      TransportTimeoutPhase.connect,
    ),
    DioExceptionType.sendTimeout => const TransportTimeout(
      TransportTimeoutPhase.send,
    ),
    DioExceptionType.receiveTimeout => const TransportTimeout(
      TransportTimeoutPhase.receive,
    ),
    // The bytes arrived and decoding them ran out of time. From the caller's
    // point of view that is indistinguishable from never receiving them, and
    // the retry question — did the server process this? — has the same answer.
    DioExceptionType.transformTimeout => const TransportTimeout(
      TransportTimeoutPhase.receive,
    ),
    DioExceptionType.connectionError => TransportOffline(
      detail: error.message,
    ),
    DioExceptionType.cancel => const TransportCancelled(),
    DioExceptionType.badCertificate => const TransportCertificateRejected(),
    // `validateStatus` above means a status alone never produces this, so
    // reaching it means the response itself was unusable.
    DioExceptionType.badResponse => _rejectedOrUnexpected(error),
    // Dio 5 reports a refused socket as `connectionError`, so anything still
    // labelled unknown here is genuinely unclassified and must not be guessed
    // at: mapping it to "offline" would make `sync` queue work that will never
    // succeed.
    DioExceptionType.unknown => TransportUnexpected(detail: error.toString()),
  };

  TransportFailure _rejectedOrUnexpected(DioException error) {
    final response = error.response;
    if (response == null) {
      return TransportUnexpected(detail: error.toString());
    }
    return TransportRejected(_toResponse(response));
  }
}
