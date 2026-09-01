@Tags(['unit'])
library;

import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:core_testing/core_testing.dart';
import 'package:dio/dio.dart';
import 'package:http_dio/http_dio.dart';
import 'package:test/test.dart';

import 'support/stub_adapter.dart';

/// Everything one of these tests needs, wired the way an app wires it.
///
/// The assertions go through [HttpTransport] rather than through `Dio`
/// directly, and that is deliberate: `DioHttpTransport` sends with
/// `validateStatus: (_) => true`, which is the reason the 401 handling lives
/// in `onResponse` at all. A test that called `dio.get` would configure the
/// client differently from every caller in the workspace and would pass while
/// production did not.
final class _Harness {
  _Harness({
    required FutureOr<ResponseBody> Function(RequestOptions, int) respond,
    String? credential,
    String? renewal,
  }) : adapter = StubAdapter(respond),
       provider = FakeAuthorizationProvider(credential: credential) {
    provider.renewal = renewal;
    dio = dioOn(adapter);
    dio.interceptors.add(
      AuthorizationInterceptor(dio: dio, provider: provider, logger: logger),
    );
    transport = DioHttpTransport(dio);
  }

  final StubAdapter adapter;
  final FakeAuthorizationProvider provider;
  final RecordingLogger logger = RecordingLogger();
  late final Dio dio;
  late final HttpTransport transport;

  /// The credential the adapter saw on attempt [attempt].
  Object? credentialOn(int attempt) =>
      adapter.calls[attempt].headers[AuthorizationInterceptor.header];
}

void main() {
  group('AuthorizationInterceptor, on the way out', () {
    test('attaches the credential the provider supplies', () async {
      final harness = _Harness(
        credential: 'Bearer live',
        respond: (_, _) => jsonBody(const {'ok': true}),
      );

      await harness.transport.send(
        const HttpRequest(method: HttpMethod.get, path: '/shipments'),
      );

      expect(harness.credentialOn(0), 'Bearer live');
    });

    test('sends nothing when nobody is signed in', () async {
      final harness = _Harness(respond: (_, _) => jsonBody(const {'ok': true}));

      await harness.transport.send(
        const HttpRequest(method: HttpMethod.get, path: '/shipments'),
      );

      expect(harness.credentialOn(0), isNull);
    });

    test(
      'leaves a credential the caller supplied alone, and does not ask for '
      'one',
      () async {
        // This is identity refreshing its own session. The header it carries is
        // the only credential that endpoint accepts, and overwriting it with
        // the access token that just expired would break the one call able to
        // fix the expiry.
        final harness = _Harness(
          credential: 'Bearer live',
          respond: (_, _) => jsonBody(const {'ok': true}),
        );

        await harness.transport.send(
          const HttpRequest(
            method: HttpMethod.post,
            path: '/sessions/refresh',
            headers: {'Authorization': 'Bearer refresh-window'},
          ),
        );

        expect(harness.credentialOn(0), 'Bearer refresh-window');
        expect(harness.provider.credentialCalls, 0);
      },
    );
  });

  group('AuthorizationInterceptor, on a refusal', () {
    test(
      'renews and replays once, and answers with the second response',
      () async {
        final harness = _Harness(
          credential: 'Bearer stale',
          renewal: 'Bearer fresh',
          respond: (_, attempt) => attempt == 0
              ? jsonBody(const {'error': 'expired'}, statusCode: 401)
              : jsonBody(const {'id': 'SHP-1'}),
        );

        final result = await harness.transport.send(
          const HttpRequest(method: HttpMethod.get, path: '/shipments/SHP-1'),
        );

        expect(result.isSuccess, isTrue);
        expect(
          (result as Success<HttpResponse, TransportFailure>).value.body,
          const {'id': 'SHP-1'},
        );
        expect(harness.adapter.callCount, 2);
        expect(harness.credentialOn(0), 'Bearer stale');
        expect(harness.credentialOn(1), 'Bearer fresh');
        expect(harness.provider.renewalCalls, 1);
      },
    );

    test(
      'replays at most once, however many times the server refuses',
      () async {
        // The guard against an infinite loop is a flag on the request rather
        // than a counter here, so the property to assert is a number of round
        // trips and not a number of renewals.
        final harness = _Harness(
          credential: 'Bearer stale',
          renewal: 'Bearer also-stale',
          respond: (_, _) =>
              jsonBody(const {'error': 'expired'}, statusCode: 401),
        );

        final result = await harness.transport.send(
          const HttpRequest(method: HttpMethod.get, path: '/shipments'),
        );

        expect(harness.adapter.callCount, 2);
        expect(harness.provider.renewalCalls, 1);
        expect(
          (result as Failed<HttpResponse, TransportFailure>).failure,
          isA<TransportRejected>().having((it) => it.statusCode, 'status', 401),
        );
      },
    );

    test('does not renew for a request it did not authorise', () async {
      // Identity's own refresh call. A 401 here means the refresh window has
      // closed, and answering it with a renewal would ask the same endpoint the
      // same question with the same secret.
      final harness = _Harness(
        credential: 'Bearer live',
        renewal: 'Bearer fresh',
        respond: (_, _) =>
            jsonBody(const {'error': 'expired'}, statusCode: 401),
      );

      await harness.transport.send(
        const HttpRequest(
          method: HttpMethod.post,
          path: '/sessions/refresh',
          headers: {'Authorization': 'Bearer refresh-window'},
        ),
      );

      expect(harness.adapter.callCount, 1);
      expect(harness.provider.renewalCalls, 0);
    });

    test(
      'does not renew when the request carried no credential at all',
      () async {
        final harness = _Harness(
          renewal: 'Bearer fresh',
          respond: (_, _) =>
              jsonBody(const {'error': 'expired'}, statusCode: 401),
        );

        await harness.transport.send(
          const HttpRequest(method: HttpMethod.post, path: '/sessions'),
        );

        expect(harness.adapter.callCount, 1);
        expect(harness.provider.renewalCalls, 0);
      },
    );

    test('passes the refusal through when nothing can be renewed', () async {
      final harness = _Harness(
        credential: 'Bearer stale',
        respond: (_, _) =>
            jsonBody(const {'error': 'expired'}, statusCode: 401),
      );

      final result = await harness.transport.send(
        const HttpRequest(method: HttpMethod.get, path: '/shipments'),
      );

      expect(harness.provider.renewalCalls, 1);
      expect(harness.adapter.callCount, 1);
      expect(
        (result as Failed<HttpResponse, TransportFailure>).failure,
        isA<TransportRejected>().having((it) => it.statusCode, 'status', 401),
      );
      expect(
        harness.logger.records.map((it) => it.message),
        contains('request refused and no credential could be renewed'),
      );
    });

    test(
      'reports the replay failing rather than the refusal it replaced',
      () async {
        final harness = _Harness(
          credential: 'Bearer stale',
          renewal: 'Bearer fresh',
          respond: (options, attempt) {
            if (attempt == 0) {
              return jsonBody(const {'error': 'expired'}, statusCode: 401);
            }
            throw DioException.connectionError(
              requestOptions: options,
              reason: 'the van left the coverage',
            );
          },
        );

        final result = await harness.transport.send(
          const HttpRequest(method: HttpMethod.get, path: '/shipments'),
        );

        expect(
          (result as Failed<HttpResponse, TransportFailure>).failure,
          isA<TransportOffline>(),
        );
      },
    );

    test('never writes a credential into the log', () async {
      final harness = _Harness(
        credential: 'Bearer secret-value',
        respond: (_, _) =>
            jsonBody(const {'error': 'expired'}, statusCode: 401),
      );

      await harness.transport.send(
        const HttpRequest(method: HttpMethod.get, path: '/shipments'),
      );

      expect(
        harness.logger.records.map((it) => '${it.message} ${it.context}'),
        everyElement(isNot(contains('secret-value'))),
      );
    });
  });
}
