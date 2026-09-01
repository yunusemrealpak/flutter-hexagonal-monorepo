import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// A Dio adapter that answers from the test instead of from a socket.
///
/// The same seam `dio_http_transport_test.dart` uses, shared here because the
/// interceptor tests need one more thing from it: the *number* of the attempt.
/// Every property worth asserting about a retry or a replay is a property of
/// the sequence — the second call carried the renewed credential, the third
/// never happened — and a stub that could not tell its calls apart could not
/// express any of them.
final class StubAdapter implements HttpClientAdapter {
  /// Answers each call with [_respond], which is handed the attempt's index.
  StubAdapter(this._respond);

  /// Answers every call the same way.
  StubAdapter.always(FutureOr<ResponseBody> Function() respond)
    : _respond = ((_, _) => respond());

  final FutureOr<ResponseBody> Function(RequestOptions options, int attempt)
  _respond;

  /// Every request that reached the adapter, oldest first.
  final List<RequestOptions> calls = [];

  /// How many requests reached the adapter.
  int get callCount => calls.length;

  /// The most recent request, or `null` when nothing was sent.
  RequestOptions? get lastCall => calls.isEmpty ? null : calls.last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final attempt = calls.length;
    // Copied rather than stored by reference: an interceptor mutates the very
    // headers a later assertion wants to read, so keeping the live object
    // would make every call look like the last one.
    calls.add(
      options.copyWith(headers: Map<String, dynamic>.of(options.headers)),
    );
    return _respond(options, attempt);
  }

  @override
  void close({bool force = false}) {}
}

/// A JSON response body with [statusCode].
ResponseBody jsonBody(
  Object? body, {
  int statusCode = 200,
  Map<String, List<String>> headers = const {},
}) => ResponseBody.fromString(
  jsonEncode(body),
  statusCode,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
    ...headers,
  },
);

/// A client that sends through [adapter] and nothing else.
///
/// No timeouts, because the stub answers immediately and a test that waited
/// for one would be a test about `Future.delayed`.
Dio dioOn(StubAdapter adapter) =>
    Dio(BaseOptions(baseUrl: 'https://peyk.test/api'))
      ..httpClientAdapter = adapter;
