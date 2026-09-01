import 'package:core_ports/core_ports.dart';
import 'package:dio/dio.dart';

import 'http_method.dart';

/// Sends a failed request again when the failure was transient and sending it
/// again is safe.
///
/// The README has always said retry policy is the adapter's business rather
/// than the caller's; this is that sentence with an implementation behind it.
/// Keeping it here rather than in a use case is what stops `_application`
/// from growing a retry loop — which it could not test without waiting, and
/// which would be a different loop in every feature.
///
/// **Only idempotent verbs are retried.** `TransportTimeout` carries the phase
/// for exactly this reason: a receive timeout means the server may well have
/// processed the request, so replaying a `POST` risks a second payment and a
/// second delivery record. `payments` binds an idempotency key to an
/// *intention* rather than to an attempt, which is what would make a retried
/// `POST` safe — but that key is the feature's knowledge and this interceptor
/// has none of it. [idempotentMethods] is therefore conservative, and a
/// feature that wants more sets [retryFlag] on the request it knows is safe.
///
/// **What counts as transient is a short list**, and everything outside it is
/// answered once. A 4xx will be refused just as firmly the second time; a
/// rejected certificate must never be retried past, because the honest reading
/// is that somebody is intercepting the connection.
///
/// **Backoff is exponential with equal jitter** — half the delay fixed, half
/// drawn from [RandomSource]. Fixed backoff synchronises every device that
/// failed at the same moment into a second simultaneous wave, which is how a
/// server that is briefly unwell is kept unwell. The randomness comes through
/// the port rather than from `Random()`, which rule A2 forbids and which would
/// make this interceptor's own tests flaky.
///
/// Like `AuthorizationInterceptor` this is a plain [Interceptor], and it reads
/// both halves of the outcome: `DioHttpTransport` sends with `validateStatus:
/// (_) => true`, so a 503 arrives at [onResponse] and only a broken connection
/// reaches [onError].
final class RetryInterceptor extends Interceptor {
  /// Retries requests sent through the client it is installed on, up to
  /// [maxAttempts] in total.
  ///
  /// [maxAttempts] counts the first send, so the default of three means two
  /// retries. [backoff] is the first delay, doubled each time.
  RetryInterceptor({
    required this._dio,
    required this._random,
    required this._logger,
    this.maxAttempts = 3,
    this.backoff = const Duration(milliseconds: 300),
    this.maxBackoff = const Duration(seconds: 8),
  }) : assert(maxAttempts >= 1, 'a request is sent at least once');

  /// The `RequestOptions.extra` key holding how many attempts have been made.
  static const String attemptFlag = 'peyk.retry.attempt';

  /// The `RequestOptions.extra` key a caller sets to opt a non-idempotent
  /// request in.
  ///
  /// The escape hatch for a feature that carries its own idempotency key and
  /// knows a repeat is harmless. Nothing sets it today; it exists so that the
  /// answer to "this `POST` is safe" is a flag on the request rather than a
  /// widened default for every `POST` in the workspace.
  static const String retryFlag = 'peyk.retry.safe';

  /// The verbs a repeat cannot duplicate anything with.
  static const Set<HttpMethod> idempotentMethods = {
    HttpMethod.get,
    HttpMethod.put,
    HttpMethod.delete,
  };

  /// The statuses worth a second attempt.
  ///
  /// 408 and 429 are the server asking for one in so many words; 500, 502, 503
  /// and 504 are the far side being briefly unwell. 501 and 505 are absent
  /// deliberately — "not implemented" does not become implemented on a retry.
  static const Set<int> retriableStatuses = {408, 429, 500, 502, 503, 504};

  /// How many times a request is sent in total, first attempt included.
  final int maxAttempts;

  /// The delay before the first retry, doubled on each subsequent one.
  final Duration backoff;

  /// The ceiling the doubling stops at.
  final Duration maxBackoff;

  final Dio _dio;
  final RandomSource _random;
  final Logger _logger;

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    final options = response.requestOptions;
    if (!retriableStatuses.contains(response.statusCode) ||
        !_mayRetry(options)) {
      return handler.next(response);
    }

    final replayed = await _replay(
      options,
      reason: 'status ${response.statusCode}',
      // A server that says how long to wait is more likely to be right than a
      // formula that cannot see its queue depth.
      after: _retryAfter(response.headers),
    );
    if (replayed == null) {
      handler.next(response);
    } else {
      handler.resolve(replayed);
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    if (!_isTransient(err.type) || !_mayRetry(options)) {
      return handler.next(err);
    }

    final replayed = await _replay(options, reason: err.type.name);
    if (replayed == null) {
      handler.next(err);
    } else {
      handler.resolve(replayed);
    }
  }

  /// Waits, sends again, and answers `null` when the second attempt failed at
  /// the transport level.
  ///
  /// A failed replay is reported as the *original* outcome rather than as its
  /// own, so that a caller sees the failure it would have seen without this
  /// interceptor. Reporting the last attempt instead would make a retried
  /// request harder to diagnose than an unretried one.
  Future<Response<dynamic>?> _replay(
    RequestOptions options, {
    required String reason,
    Duration? after,
  }) async {
    final attempt = _attemptOf(options);
    final delay = after ?? _delayFor(attempt);

    _logger.info(
      'retrying a request',
      context: {
        'path': options.path,
        'method': options.method,
        'attempt': attempt + 1,
        'of': maxAttempts,
        'reason': reason,
        'inMilliseconds': delay.inMilliseconds,
      },
    );

    await Future<void>.delayed(delay);
    options.extra[attemptFlag] = attempt + 1;

    try {
      return await _dio.fetch<dynamic>(options);
    } on DioException {
      return null;
    }
  }

  /// Equal jitter: half the window fixed, half of it drawn.
  Duration _delayFor(int attempt) {
    final doubled = backoff.inMilliseconds * (1 << attempt);
    final capped = doubled.clamp(1, maxBackoff.inMilliseconds);
    final half = capped ~/ 2;
    return Duration(milliseconds: half + _random.nextInt(half + 1));
  }

  bool _mayRetry(RequestOptions options) =>
      _attemptOf(options) + 1 < maxAttempts && _isSafeToRepeat(options);

  bool _isSafeToRepeat(RequestOptions options) {
    if (options.extra[retryFlag] == true) return true;
    final method = options.method.toLowerCase();
    return idempotentMethods.any((it) => it.name == method);
  }

  static int _attemptOf(RequestOptions options) {
    final recorded = options.extra[attemptFlag];
    return recorded is int ? recorded : 0;
  }

  static bool _isTransient(DioExceptionType type) => switch (type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.transformTimeout ||
    DioExceptionType.connectionError => true,
    // Never. A refused certificate may mean the connection is being
    // intercepted, and a cancelled request was cancelled on purpose.
    DioExceptionType.badCertificate ||
    DioExceptionType.cancel ||
    DioExceptionType.badResponse ||
    DioExceptionType.unknown => false,
  };

  /// Reads `Retry-After`, in the delta-seconds form servers actually send.
  ///
  /// The HTTP-date form is legal and rare; an unparsable value falls back to
  /// the computed backoff rather than to no delay at all, because a header
  /// nobody can read is not permission to hammer.
  static Duration? _retryAfter(Headers headers) {
    final raw = headers.value('retry-after');
    if (raw == null) return null;
    final seconds = int.tryParse(raw.trim());
    return seconds == null ? null : Duration(seconds: seconds);
  }
}
