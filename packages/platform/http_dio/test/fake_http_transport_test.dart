@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:http_dio/http_dio.dart';
import 'package:test/test.dart';

void main() {
  group('FakeHttpTransport', () {
    test('answers queued responses in order', () async {
      final transport = FakeHttpTransport()
        ..enqueueJson(const {'page': 1})
        ..enqueueJson(const {'page': 2});

      final first = await transport.send(
        const HttpRequest(method: HttpMethod.get, path: '/shipments'),
      );
      final second = await transport.send(
        const HttpRequest(method: HttpMethod.get, path: '/shipments?page=2'),
      );

      expect((first as Success<HttpResponse, TransportFailure>).value.body, {
        'page': 1,
      });
      expect((second as Success<HttpResponse, TransportFailure>).value.body, {
        'page': 2,
      });
    });

    test(
      'records every request, so a test can assert what was built',
      () async {
        final transport = FakeHttpTransport()..enqueueJson(null);

        await transport.send(
          const HttpRequest(
            method: HttpMethod.post,
            path: '/shipments/SHP-1/assign',
            body: {'courierId': 'CUR-9'},
          ),
        );

        expect(transport.requests, hasLength(1));
        expect(transport.lastRequest?.method, HttpMethod.post);
        expect(transport.lastRequest?.path, '/shipments/SHP-1/assign');
        expect(transport.lastRequest?.body, {'courierId': 'CUR-9'});
      },
    );

    test('can be told to fail, so failure branches stay tested', () async {
      final transport = FakeHttpTransport()
        ..enqueueFailure(const TransportTimeout(TransportTimeoutPhase.receive))
        ..enqueueJson(const {'ok': true});

      final failed = await transport.send(
        const HttpRequest(method: HttpMethod.get, path: '/ping'),
      );
      final retried = await transport.send(
        const HttpRequest(method: HttpMethod.get, path: '/ping'),
      );

      // A queue rather than a single canned answer is what lets a test drive a
      // retry: fail once, succeed once, assert the caller tried twice.
      expect(failed.isFailure, isTrue);
      expect(retried.isSuccess, isTrue);
      expect(transport.requests, hasLength(2));
    });

    test('fails rather than throws when nothing is queued', () async {
      final transport = FakeHttpTransport();

      final result = await transport.send(
        const HttpRequest(method: HttpMethod.get, path: '/ping'),
      );

      // The fake obeys the contract it imitates even when it is misused: this
      // port does not throw.
      final failure =
          (result as Failed<HttpResponse, TransportFailure>).failure;
      expect(failure, isA<TransportUnexpected>());
      expect(
        (failure as TransportUnexpected).detail,
        contains('nothing queued'),
      );
    });

    test('reset forgets both the queue and the recorded requests', () async {
      final transport = FakeHttpTransport()..enqueueJson(null);
      await transport.send(
        const HttpRequest(method: HttpMethod.get, path: '/ping'),
      );

      transport.reset();

      expect(transport.requests, isEmpty);
      expect(transport.lastRequest, isNull);
    });
  });
}
