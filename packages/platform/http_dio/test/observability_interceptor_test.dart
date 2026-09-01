@Tags(['unit'])
library;

import 'package:core_ports/core_ports.dart';
import 'package:core_testing/core_testing.dart';
import 'package:dio/dio.dart';
import 'package:http_dio/http_dio.dart';
import 'package:test/test.dart';

import 'support/stub_adapter.dart';

void main() {
  late FakeClock clock;
  late RecordingLogger logger;
  late FakeIdGenerator ids;

  setUp(() {
    clock = FakeClock();
    logger = RecordingLogger();
    ids = FakeIdGenerator.scripted(['req-1', 'req-2']);
  });

  HttpTransport transportOver(StubAdapter adapter) {
    final dio = dioOn(adapter)
      ..interceptors.add(
        ObservabilityInterceptor(logger: logger, ids: ids, clock: clock),
      );
    return DioHttpTransport(dio);
  }

  test('stamps a correlation identifier on a request that has none', () async {
    final adapter = StubAdapter.always(() => jsonBody(const {'ok': true}));

    await transportOver(adapter).send(
      const HttpRequest(method: HttpMethod.get, path: '/shipments'),
    );

    expect(
      adapter.lastCall!.headers[ObservabilityInterceptor.correlationHeader],
      'req-1',
    );
  });

  test('keeps an identifier the caller already chose', () async {
    // A `sync` command carries its own, so that the row in the outbox and the
    // row on the server are the same row. Minting a second here would break
    // the only join that connects them.
    final adapter = StubAdapter.always(() => jsonBody(const {'ok': true}));

    await transportOver(adapter).send(
      const HttpRequest(
        method: HttpMethod.get,
        path: '/shipments',
        headers: {'X-Request-Id': 'chosen-by-the-caller'},
      ),
    );

    expect(
      adapter.lastCall!.headers[ObservabilityInterceptor.correlationHeader],
      'chosen-by-the-caller',
    );
    expect(ids.issuedCount, 0);
  });

  test('records how long the call took, off the injected clock', () async {
    final adapter = StubAdapter.always(() {
      clock.advance(const Duration(milliseconds: 250));
      return jsonBody(const {'ok': true});
    });

    await transportOver(adapter).send(
      const HttpRequest(method: HttpMethod.get, path: '/shipments'),
    );

    expect(logger.records.single.context['inMilliseconds'], 250);
  });

  test(
    'reports a server failure at a level worth reading, and a 404 not',
    () async {
      final failing = StubAdapter.always(
        () => jsonBody(const {'error': 'down'}, statusCode: 503),
      );
      await transportOver(failing).send(
        const HttpRequest(method: HttpMethod.get, path: '/shipments'),
      );
      expect(logger.records.single.level, LogLevel.warning);

      logger.clear();

      final missing = StubAdapter.always(
        () => jsonBody(const {'error': 'gone'}, statusCode: 404),
      );
      // A 4xx is the server answering, not the app breaking. Logging every one
      // of them as a warning is how a log stops being read.
      await transportOver(missing).send(
        const HttpRequest(method: HttpMethod.get, path: '/shipments/SHP-9'),
      );
      expect(logger.records.single.level, LogLevel.debug);
    },
  );

  test(
    'records a broken connection as a failure rather than a status',
    () async {
      final adapter = StubAdapter(
        (options, _) => throw DioException.connectionError(
          requestOptions: options,
          reason: 'no route',
        ),
      );

      await transportOver(adapter).send(
        const HttpRequest(method: HttpMethod.get, path: '/shipments'),
      );

      final record = logger.records.single;
      expect(record.message, 'request failed');
      expect(record.context['type'], 'connectionError');
    },
  );

  test('writes no header, body or query value into the record', () async {
    // The defence against a bearer token reaching a log aggregator is that the
    // line is never built with one in it. Dio's own LogInterceptor prints
    // headers by default, which is why this package does not use it.
    final adapter = StubAdapter.always(() => jsonBody(const {'ok': true}));

    await transportOver(adapter).send(
      const HttpRequest(
        method: HttpMethod.get,
        path: '/shipments',
        query: {'courier': 'ACT-secret'},
        headers: {'Authorization': 'Bearer secret-value'},
      ),
    );

    final rendered = '${logger.records.single.context}';
    expect(rendered, isNot(contains('secret-value')));
    expect(rendered, isNot(contains('ACT-secret')));
    expect(rendered, contains('/shipments'));
  });
}
