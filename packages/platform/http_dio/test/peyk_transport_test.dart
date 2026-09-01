@Tags(['unit'])
library;

import 'dart:async';

import 'package:core_testing/core_testing.dart';
import 'package:dio/dio.dart';
import 'package:http_dio/http_dio.dart';
import 'package:test/test.dart';

import 'support/stub_adapter.dart';

/// The chain as an application assembles it.
///
/// The three interceptors have their own tests; this file is about what only
/// shows up when they run together, which is the part an app would otherwise
/// discover in production.
final class _Harness {
  _Harness({
    required FutureOr<ResponseBody> Function(RequestOptions, int) respond,
    String? credential,
    String? renewal,
  }) : adapter = StubAdapter(respond),
       provider = FakeAuthorizationProvider(credential: credential) {
    provider.renewal = renewal;
    dio = dioOn(adapter);
    PeykTransport.installOn(
      dio,
      authorization: provider,
      logger: logger,
      ids: ids,
      clock: FakeClock(),
      random: FakeRandomSource(const [0]),
    );
    transport = DioHttpTransport(dio);
  }

  final StubAdapter adapter;
  final FakeAuthorizationProvider provider;
  final RecordingLogger logger = RecordingLogger();
  final FakeIdGenerator ids = FakeIdGenerator('req');
  late final Dio dio;
  late final HttpTransport transport;

  /// The correlation identifier each attempt carried.
  List<Object?> get correlationIds => adapter.calls
      .map((it) => it.headers[ObservabilityInterceptor.correlationHeader])
      .toList();
}

void main() {
  group('PeykTransport.optionsFor', () {
    test('carries the base URL it was given and nothing else about it', () {
      final options = PeykTransport.optionsFor('https://api.peyk.example');

      expect(options.baseUrl, 'https://api.peyk.example');
    });

    test('bounds every phase of the exchange', () {
      // The defect this exists to prevent: both applications built
      // `Dio(BaseOptions(baseUrl: …))`, which leaves all three null — Dio's
      // documented spelling of "wait forever" — so `TransportTimeout` was a
      // case production could not reach.
      final options = PeykTransport.optionsFor('https://api.peyk.example');

      expect(options.connectTimeout, isNotNull);
      expect(options.sendTimeout, isNotNull);
      expect(options.receiveTimeout, isNotNull);
    });
  });

  group('PeykTransport.installOn', () {
    test('installs the three, in the order the chain depends on', () {
      final dio = dioOn(StubAdapter.always(() => jsonBody(null)));

      PeykTransport.installOn(
        dio,
        authorization: FakeAuthorizationProvider(),
        logger: RecordingLogger(),
        ids: FakeIdGenerator(),
        clock: FakeClock(),
        random: FakeRandomSource(),
      );

      // Dio installs one of its own first — the interceptor that infers a
      // content type — so the assertion is about the tail rather than the
      // whole list.
      expect(
        dio.interceptors
            .skip(dio.interceptors.length - 3)
            .map((it) => it.runtimeType)
            .toList(),
        [
          ObservabilityInterceptor,
          AuthorizationInterceptor,
          RetryInterceptor,
        ],
      );
    });
  });

  group('the chain, on an expired token', () {
    test(
      'renews, replays, and reports both attempts under one identifier',
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
        expect(harness.adapter.callCount, 2);

        // One logical call, one identifier. A second identifier here would make
        // the retry look like an unrelated request in whatever collects the
        // records, which is precisely when somebody is looking for it.
        expect(harness.correlationIds, ['req-1', 'req-1']);
        expect(harness.ids.issuedCount, 1);

        // And the retry interceptor stayed out of it: a refused credential is
        // not a transient failure, and spending an attempt on one would waste
        // the budget the next genuinely transient failure needs.
        expect(
          harness.logger.records.map((it) => it.message),
          isNot(contains('retrying a request')),
        );
      },
    );
  });

  group('the chain, on a server that is briefly unwell', () {
    test('retries with the credential still attached', () async {
      final harness = _Harness(
        credential: 'Bearer live',
        respond: (_, attempt) => attempt == 0
            ? jsonBody(const {'error': 'busy'}, statusCode: 503)
            : jsonBody(const {'id': 'SHP-1'}),
      );

      final result = await harness.transport.send(
        const HttpRequest(method: HttpMethod.get, path: '/shipments/SHP-1'),
      );

      expect(result.isSuccess, isTrue);
      expect(harness.adapter.callCount, 2);
      expect(
        harness.adapter.calls
            .map((it) => it.headers[AuthorizationInterceptor.header])
            .toList(),
        ['Bearer live', 'Bearer live'],
      );
      // Asked once, not once per attempt: the replay carries the request Dio
      // already built rather than being composed again from scratch.
      expect(harness.provider.credentialCalls, 1);
      expect(harness.correlationIds, ['req-1', 'req-1']);
    });
  });
}
