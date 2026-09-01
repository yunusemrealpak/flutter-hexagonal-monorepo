@Tags(['unit'])
library;

import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:core_testing/core_testing.dart';
import 'package:dio/dio.dart';
import 'package:http_dio/http_dio.dart';
import 'package:test/test.dart';

import 'support/stub_adapter.dart';

/// A transport that retries, wired the way an app wires it.
///
/// The backoff is a millisecond rather than the production default, because
/// these tests are about *which* requests are sent again and how the delay is
/// computed — not about waiting. The one test that cares about the number
/// reads it out of the log line rather than off a stopwatch, which is the
/// difference between an assertion and a race.
final class _Harness {
  _Harness({
    required FutureOr<ResponseBody> Function(RequestOptions, int) respond,
    List<double> jitter = const [0],
    int maxAttempts = 3,
    Duration backoff = const Duration(milliseconds: 1),
  }) : adapter = StubAdapter(respond) {
    dio = dioOn(adapter);
    dio.interceptors.add(
      RetryInterceptor(
        dio: dio,
        random: FakeRandomSource(jitter),
        logger: logger,
        maxAttempts: maxAttempts,
        backoff: backoff,
      ),
    );
    transport = DioHttpTransport(dio);
  }

  final StubAdapter adapter;
  final RecordingLogger logger = RecordingLogger();
  late final Dio dio;
  late final HttpTransport transport;

  /// The delay each retry announced, in milliseconds.
  List<Object?> get announcedDelays => logger.records
      .where((it) => it.message == 'retrying a request')
      .map((it) => it.context['inMilliseconds'])
      .toList();
}

void main() {
  group('RetryInterceptor, on a status', () {
    test(
      'sends an idempotent request again and answers with the retry',
      () async {
        final harness = _Harness(
          respond: (_, attempt) => attempt == 0
              ? jsonBody(const {'error': 'busy'}, statusCode: 503)
              : jsonBody(const {'id': 'SHP-1'}),
        );

        final result = await harness.transport.send(
          const HttpRequest(method: HttpMethod.get, path: '/shipments/SHP-1'),
        );

        expect(harness.adapter.callCount, 2);
        expect(
          (result as Success<HttpResponse, TransportFailure>).value.body,
          const {'id': 'SHP-1'},
        );
      },
    );

    test('stops at the attempt budget', () async {
      final harness = _Harness(
        respond: (_, _) => jsonBody(const {'error': 'busy'}, statusCode: 503),
      );

      final result = await harness.transport.send(
        const HttpRequest(method: HttpMethod.get, path: '/shipments'),
      );

      expect(harness.adapter.callCount, 3);
      expect(
        (result as Failed<HttpResponse, TransportFailure>).failure,
        isA<TransportRejected>().having((it) => it.statusCode, 'status', 503),
      );
    });

    test('leaves a POST alone, however transient the failure looks', () async {
      // The whole reason `TransportTimeout` carries a phase. A repeated POST is
      // a second payment or a second delivery record, and this interceptor has
      // no idempotency key to make it safe.
      final harness = _Harness(
        respond: (_, _) => jsonBody(const {'error': 'busy'}, statusCode: 503),
      );

      await harness.transport.send(
        const HttpRequest(method: HttpMethod.post, path: '/delivery/proofs'),
      );

      expect(harness.adapter.callCount, 1);
    });

    test('retries a POST the caller declared safe to repeat', () async {
      final harness = _Harness(
        respond: (_, attempt) => attempt == 0
            ? jsonBody(const {'error': 'busy'}, statusCode: 503)
            : jsonBody(const {'ok': true}),
      );

      // The escape hatch a feature with its own idempotency key would use.
      harness.dio.options.extra[RetryInterceptor.retryFlag] = true;

      await harness.transport.send(
        const HttpRequest(method: HttpMethod.post, path: '/payments/intents'),
      );

      expect(harness.adapter.callCount, 2);
    });

    test('answers a 404 once', () async {
      final harness = _Harness(
        respond: (_, _) => jsonBody(const {'error': 'gone'}, statusCode: 404),
      );

      await harness.transport.send(
        const HttpRequest(method: HttpMethod.get, path: '/shipments/SHP-9'),
      );

      expect(harness.adapter.callCount, 1);
    });
  });

  group('RetryInterceptor, on a broken connection', () {
    test('sends again after a connection error', () async {
      final harness = _Harness(
        respond: (options, attempt) {
          if (attempt == 0) {
            throw DioException.connectionError(
              requestOptions: options,
              reason: 'the van entered a tunnel',
            );
          }
          return jsonBody(const {'id': 'SHP-1'});
        },
      );

      final result = await harness.transport.send(
        const HttpRequest(method: HttpMethod.get, path: '/shipments/SHP-1'),
      );

      expect(harness.adapter.callCount, 2);
      expect(result.isSuccess, isTrue);
    });

    test('never sends again past a rejected certificate', () async {
      // The one failure here that may mean somebody is intercepting the
      // connection. Retrying it would be retrying into the interception.
      final harness = _Harness(
        respond: (options, _) => throw DioException(
          requestOptions: options,
          type: DioExceptionType.badCertificate,
        ),
      );

      final result = await harness.transport.send(
        const HttpRequest(method: HttpMethod.get, path: '/shipments'),
      );

      expect(harness.adapter.callCount, 1);
      expect(
        (result as Failed<HttpResponse, TransportFailure>).failure,
        isA<TransportCertificateRejected>(),
      );
    });
  });

  group('RetryInterceptor, on the delay it waits', () {
    test('draws the jitter half of the window from the source', () async {
      Future<List<Object?>> delaysWith(List<double> jitter) async {
        final harness = _Harness(
          jitter: jitter,
          maxAttempts: 2,
          backoff: const Duration(milliseconds: 40),
          respond: (_, _) => jsonBody(const {'error': 'busy'}, statusCode: 503),
        );
        await harness.transport.send(
          const HttpRequest(method: HttpMethod.get, path: '/shipments'),
        );
        return harness.announcedDelays;
      }

      // Half the window is fixed and half is drawn, so the lowest draw is 20ms
      // of a 40ms window and the highest is the whole of it. Fixed backoff
      // would produce one number for both, which is what synchronises every
      // device that failed at the same moment into a second simultaneous wave.
      expect(await delaysWith(const [0]), [20]);
      expect(await delaysWith(const [0.99]), [40]);
    });

    test('prefers what the server asked for over what it computed', () async {
      final harness = _Harness(
        maxAttempts: 2,
        backoff: const Duration(milliseconds: 40),
        respond: (_, _) => jsonBody(
          const {'error': 'slow down'},
          statusCode: 429,
          headers: {
            'retry-after': ['0'],
          },
        ),
      );

      await harness.transport.send(
        const HttpRequest(method: HttpMethod.get, path: '/shipments'),
      );

      // The computed delay could not have been zero — the window's fixed half
      // is 20ms — so a zero here can only have come from the header.
      expect(harness.announcedDelays, [0]);
    });
  });
}
