@Tags(['unit'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:core_kernel/core_kernel.dart';
import 'package:dio/dio.dart';
import 'package:http_dio/http_dio.dart';
import 'package:test/test.dart';

/// A Dio adapter that answers from the test instead of from a socket.
///
/// Dio's own replaceable seam, used here for the same reason the workspace
/// puts a seam behind every port: the adapter under test is the translation
/// between Dio and [TransportFailure], and translating is only observable when
/// the thing being translated is something the test chose.
final class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this._respond);

  final FutureOr<ResponseBody> Function(RequestOptions options) _respond;

  RequestOptions? lastOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
    return _respond(options);
  }

  @override
  void close({bool force = false}) {}
}

Dio _dioAnswering(
  FutureOr<ResponseBody> Function(RequestOptions options) respond, {
  _StubAdapter? adapter,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://peyk.test/api'))
    ..httpClientAdapter = adapter ?? _StubAdapter(respond);
  return dio;
}

ResponseBody _json(Object? body, {int statusCode = 200}) =>
    ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

void main() {
  group('DioHttpTransport.send', () {
    test('returns the decoded body of a 2xx response', () async {
      final transport = DioHttpTransport(
        _dioAnswering((_) => _json({'id': 'SHP-1', 'state': 'assigned'})),
      );

      final result = await transport.send(
        const HttpRequest(method: HttpMethod.get, path: '/shipments/SHP-1'),
      );

      expect(result.isSuccess, isTrue);
      final response =
          (result as Success<HttpResponse, TransportFailure>).value;
      expect(response.statusCode, 200);
      expect(response.body, {'id': 'SHP-1', 'state': 'assigned'});
    });

    test('carries the verb, path, query and headers through to Dio', () async {
      final adapter = _StubAdapter((_) => _json(const {'ok': true}));
      final transport = DioHttpTransport(
        _dioAnswering((_) => _json(null), adapter: adapter),
      );

      await transport.send(
        const HttpRequest(
          method: HttpMethod.post,
          path: '/shipments',
          query: {'dryRun': 'true'},
          headers: {'x-request-id': 'req-7'},
          body: {'reference': 'ABC'},
        ),
      );

      final options = adapter.lastOptions!;
      expect(options.method, 'POST');
      expect(options.path, '/shipments');
      expect(
        options.uri.toString(),
        'https://peyk.test/api/shipments?dryRun=true',
      );
      expect(options.headers['x-request-id'], 'req-7');
      expect(options.data, {'reference': 'ABC'});
    });

    test(
      'reports a non-2xx status as TransportRejected with the body intact',
      () async {
        final transport = DioHttpTransport(
          _dioAnswering(
            (_) => _json(const {'error': 'shipment_locked'}, statusCode: 409),
          ),
        );

        final result = await transport.send(
          const HttpRequest(
            method: HttpMethod.post,
            path: '/shipments/SHP-1/assign',
          ),
        );

        final failure =
            (result as Failed<HttpResponse, TransportFailure>).failure;
        expect(failure, isA<TransportRejected>());
        final rejected = failure as TransportRejected;
        expect(rejected.statusCode, 409);
        // The reason an API puts in a 4xx body has to survive the crossing, or
        // the calling adapter has nothing to map to a domain failure.
        expect(rejected.response.body, {'error': 'shipment_locked'});
      },
    );

    test('maps each Dio timeout to the phase it happened in', () async {
      const phases = {
        DioExceptionType.connectionTimeout: TransportTimeoutPhase.connect,
        DioExceptionType.sendTimeout: TransportTimeoutPhase.send,
        DioExceptionType.receiveTimeout: TransportTimeoutPhase.receive,
      };

      for (final entry in phases.entries) {
        final transport = DioHttpTransport(
          _dioAnswering(
            (options) =>
                throw DioException(requestOptions: options, type: entry.key),
          ),
        );

        final result = await transport.send(
          const HttpRequest(method: HttpMethod.get, path: '/ping'),
        );

        final failure =
            (result as Failed<HttpResponse, TransportFailure>).failure;
        expect(failure, isA<TransportTimeout>(), reason: '${entry.key}');
        expect((failure as TransportTimeout).phase, entry.value);
      }
    });

    test('maps a connection error to TransportOffline', () async {
      final transport = DioHttpTransport(
        _dioAnswering(
          (options) => throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
            message: 'no route to host',
          ),
        ),
      );

      final result = await transport.send(
        const HttpRequest(method: HttpMethod.get, path: '/ping'),
      );

      final failure =
          (result as Failed<HttpResponse, TransportFailure>).failure;
      expect(failure, isA<TransportOffline>());
      expect((failure as TransportOffline).detail, 'no route to host');
    });

    test('maps a rejected certificate to its own case', () async {
      final transport = DioHttpTransport(
        _dioAnswering(
          (options) => throw DioException(
            requestOptions: options,
            type: DioExceptionType.badCertificate,
          ),
        ),
      );

      final result = await transport.send(
        const HttpRequest(method: HttpMethod.get, path: '/ping'),
      );

      expect(
        (result as Failed<HttpResponse, TransportFailure>).failure,
        isA<TransportCertificateRejected>(),
      );
    });

    test('maps a cancellation to TransportCancelled', () async {
      final transport = DioHttpTransport(
        _dioAnswering(
          (options) => throw DioException(
            requestOptions: options,
            type: DioExceptionType.cancel,
          ),
        ),
      );

      final result = await transport.send(
        const HttpRequest(method: HttpMethod.get, path: '/ping'),
      );

      expect(
        (result as Failed<HttpResponse, TransportFailure>).failure,
        isA<TransportCancelled>(),
      );
    });

    test('lets no exception escape, whatever Dio does', () async {
      final transport = DioHttpTransport(
        _dioAnswering((_) => throw StateError('something Dio never promised')),
      );

      final result = await transport.send(
        const HttpRequest(method: HttpMethod.get, path: '/ping'),
      );

      // Invariant 1.2.9: the adapter is the boundary. Whatever happens below
      // it becomes a value above it.
      expect(result.isFailure, isTrue);
    });
  });
}
