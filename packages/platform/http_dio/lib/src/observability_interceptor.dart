import 'package:core_ports/core_ports.dart';
import 'package:dio/dio.dart';

import 'authorization_interceptor.dart';

/// Gives every request a correlation identifier and records what became of it.
///
/// Two jobs that belong together because they answer one question — *what
/// happened to this call?* — and because they are the two things that are
/// impossible to add later without touching every gateway. A correlation
/// identifier minted here appears on the request the server logs and on the
/// line this interceptor writes, so a courier's report of a failure at 14:03
/// resolves to a row rather than to a search.
///
/// **Nothing here logs a header, a body or a query value.** The
/// `Authorization` header is a live bearer token, and Dio's own
/// `LogInterceptor` prints headers by default — which is why this package does
/// not use it. `AccessToken.toString` redacts for the same reason one layer
/// up; a log line is the likeliest place for a secret to escape, and the only
/// defence that works is not building the line. The record carries the verb,
/// the path, the status, the duration and the identifier, and every one of
/// those is safe to keep.
///
/// The clock arrives through [Clock] rather than from a `Stopwatch` so that a
/// test can state a duration instead of measuring one, and because the port is
/// already there.
final class ObservabilityInterceptor extends Interceptor {
  /// Records requests through the logger given, identifying them with the
  /// generator given.
  ObservabilityInterceptor({
    required this._logger,
    required this._ids,
    required this._clock,
  });

  /// The header the correlation identifier travels in.
  ///
  /// The de facto convention, and deliberately not `traceparent`: this is one
  /// identifier for one call, not a W3C trace context, and claiming the
  /// standard header would mislead whatever collects it.
  static const String correlationHeader = 'X-Request-Id';

  /// The `RequestOptions.extra` key holding when the request left.
  static const String startedAtFlag = 'peyk.observability.startedAt';

  final Logger _logger;
  final IdGenerator _ids;
  final Clock _clock;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    // A replay keeps the identifier it was first given. The whole point is
    // that one logical call reads as one identifier across its attempts —
    // minting a second here would turn a retried request into two unrelated
    // rows and hide the retry.
    options.headers.putIfAbsent(correlationHeader, _ids.newId);
    options.extra.putIfAbsent(startedAtFlag, _clock.now);
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final status = response.statusCode ?? 0;
    _record(
      // A 4xx is the server's answer rather than the app's fault, and logging
      // every 404 as a warning is how a log stops being read. 5xx is the far
      // side failing and is worth the level.
      status >= 500 ? LogLevel.warning : LogLevel.debug,
      'request completed',
      response.requestOptions,
      extra: {'status': status},
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _record(
      LogLevel.warning,
      'request failed',
      err.requestOptions,
      extra: {'type': err.type.name},
    );
    handler.next(err);
  }

  void _record(
    LogLevel level,
    String message,
    RequestOptions options, {
    required Map<String, Object?> extra,
  }) {
    final startedAt = options.extra[startedAtFlag];
    _logger.log(
      level,
      message,
      context: {
        'method': options.method,
        'path': options.path,
        'requestId': options.headers[correlationHeader],
        if (startedAt is DateTime)
          'inMilliseconds': _clock.now().difference(startedAt).inMilliseconds,
        // Present only on a request that was authorised, and never the
        // credential itself: whether a call carried one is the question a
        // 401 investigation actually asks.
        if (options.extra[AuthorizationInterceptor.attachedFlag] == true)
          'authorized': true,
        ...extra,
      },
    );
  }
}
