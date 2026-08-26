@Tags(['unit'])
library;

import 'package:core_testing/core_testing.dart';
import 'package:http_dio/http_dio.dart';
import 'package:sync_api/sync_api.dart';
import 'package:sync_infrastructure/sync_infrastructure.dart';
import 'package:sync_testing/sync_testing.dart';
import 'package:test/test.dart';

void main() {
  late FakeHttpTransport http;
  late HttpCommandTransport transport;

  SyncEnvelope envelope() => OutboxEntryBuilder()
      .withId('e-1')
      .ofType('delivery.completeAttempt')
      .under(const ConflictPolicy.manualReview())
      .build()
      .envelopeFor(cursor: const SyncCursor('c-1'));

  setUp(() {
    http = FakeHttpTransport();
    transport = HttpCommandTransport(transport: http);
  });

  group('the request', () {
    test('posts the envelope to the commands endpoint', () async {
      http.enqueueJson(<String, dynamic>{'cursor': 'c-2'});

      await transport.send(envelope());

      final request = http.lastRequest!;
      expect(request.method, HttpMethod.post);
      expect(request.path, '/sync/commands');
    });

    test('carries the entry identifier as an idempotency header', () async {
      // In the header as well as the body, because that is where a server's
      // idempotency middleware looks — usually before anything has parsed the
      // body at all.
      http.enqueueJson(<String, dynamic>{'cursor': 'c-2'});

      await transport.send(envelope());

      expect(http.lastRequest!.headers['Idempotency-Key'], 'e-1');
    });

    test('sends the payload untouched and the policy as a string', () async {
      http.enqueueJson(<String, dynamic>{'cursor': 'c-2'});

      await transport.send(envelope());

      final body = http.lastRequest!.body! as Map<String, dynamic>;
      expect(body['type'], 'delivery.completeAttempt');
      expect(body['payload'], isA<String>());
      expect(body['policy'], 'manualReview');
      expect(body['cursor'], 'c-1');
      expect(body['attempt'], 1);
    });

    test('sends the queued instant in UTC', () async {
      // The line that is easy to omit and hard to notice missing: a device set
      // to Istanbul time would otherwise send local instants the server reads
      // as UTC, and every offline write would look three hours early.
      http.enqueueJson(<String, dynamic>{'cursor': 'c-2'});

      await transport.send(envelope());

      final body = http.lastRequest!.body! as Map<String, dynamic>;
      expect(body['queuedAt'], endsWith('Z'));
    });
  });

  group('the answer', () {
    test('reports the position the server issued', () async {
      http.enqueueJson(<String, dynamic>{'cursor': 'c-9'});

      final sent = await transport.send(envelope());

      expect(
        sent.fold((c) => c, (f) => throw StateError('$f')),
        const SyncCursor('c-9'),
      );
    });

    test('treats a 2xx that says conflict as a conflict', () async {
      // The most expensive mistake available in this file would be to read
      // this as an acceptance: the drain would drop the entry and the write
      // would be gone.
      http.enqueueJson(<String, dynamic>{
        'conflict': true,
        'cursor': 'c-99',
        'reason': 'newer write exists',
      });

      final sent = await transport.send(envelope());

      expect(
        sent.fold((_) => null, (f) => f),
        const SyncConflict(cursor: 'c-99', detail: 'newer write exists'),
      );
    });

    test(
      'reports a body it cannot read rather than assuming success',
      () async {
        http.enqueueJson('not an object');

        expect((await transport.send(envelope())).isFailure, isTrue);
      },
    );

    test('reports an acknowledgement with no position', () async {
      http.enqueueJson(<String, dynamic>{});

      expect((await transport.send(envelope())).isFailure, isTrue);
    });
  });

  group('the translation table', () {
    // The only place in the feature where a status code exists. Every row here
    // is a decision DrainOutbox acts on without knowing HTTP is involved.

    Future<SyncFailure> failureFor(TransportFailure failure) async {
      http.enqueueFailure(failure);
      final sent = await transport.send(envelope());
      return sent.fold(
        (_) => throw StateError('expected a failure'),
        (f) => f,
      );
    }

    test(
      'offline stays offline, so the drain stops without an attempt',
      () async {
        expect(await failureFor(const TransportOffline()), const SyncOffline());
      },
    );

    test('a timeout is transient', () async {
      final failure = await failureFor(
        const TransportTimeout(TransportTimeoutPhase.receive),
      );

      expect(failure.isTransient, isTrue);
    });

    test('a 5xx is transient and a 4xx is not', () async {
      // The split that stops a deploy turning a fleet's queues into a review
      // backlog, and stops a malformed command being retried forever.
      final server = await failureFor(
        const TransportRejected(HttpResponse(statusCode: 503)),
      );
      final client = await failureFor(
        const TransportRejected(HttpResponse(statusCode: 422)),
      );

      expect(server.isTransient, isTrue);
      expect(client.isTransient, isFalse);
      expect(client, isA<SyncRejected>());
    });

    test('a 409 is a conflict, carrying the position it came with', () async {
      final failure = await failureFor(
        const TransportRejected(
          HttpResponse(
            statusCode: 409,
            body: <String, dynamic>{'cursor': 'c-77'},
          ),
        ),
      );

      expect(failure, isA<SyncConflict>());
      expect((failure as SyncConflict).cursor, 'c-77');
    });

    test('a cancelled request is transient, not a rejection', () async {
      expect(
        (await failureFor(const TransportCancelled())).isTransient,
        isTrue,
      );
    });

    test('no TransportFailure ever reaches the caller', () async {
      // Invariant 1.2.9's other half: the port promises SyncFailure, and a
      // TransportRejected escaping here would be a retry policy that stops
      // compiling the day the API becomes gRPC.
      final failures = <TransportFailure>[
        const TransportOffline(),
        const TransportTimeout(TransportTimeoutPhase.connect),
        const TransportRejected(HttpResponse(statusCode: 500)),
        const TransportCancelled(),
        const TransportCertificateRejected(),
        const TransportUnexpected(detail: 'something'),
      ];

      for (final failure in failures) {
        expect(await failureFor(failure), isA<SyncFailure>());
      }
    });
  });

  group('HttpClockSkew', () {
    late FakeClock clock;
    late HttpClockSkew skew;

    setUp(() {
      clock = FakeClock(DateTime.utc(2026, 3, 14, 12));
      skew = HttpClockSkew(transport: http, clock: clock);
    });

    test('reports how far the server is ahead of the device', () async {
      http.enqueueJson(<String, dynamic>{'now': '2026-03-14T12:02:00Z'});

      final measured = await skew.skew();

      expect(
        measured.fold((d) => d, (f) => throw StateError('$f')),
        const Duration(minutes: 2),
      );
    });

    test('reports a negative difference when the device is ahead', () async {
      http.enqueueJson(<String, dynamic>{'now': '2026-03-14T11:58:00Z'});

      final measured = await skew.skew();

      expect(
        measured.fold((d) => d, (f) => throw StateError('$f')),
        const Duration(minutes: -2),
      );
    });

    test('asks once and reuses the answer inside its lifetime', () async {
      // Asking on every drain would put a request in front of every batch of
      // work, which is a strange thing to do on a device whose defining
      // problem is that requests are expensive.
      http.enqueueJson(<String, dynamic>{'now': '2026-03-14T12:02:00Z'});

      await skew.skew();
      await skew.skew();

      expect(http.requests, hasLength(1));
    });

    test('asks again once the answer has gone stale', () async {
      http
        ..enqueueJson(<String, dynamic>{'now': '2026-03-14T12:02:00Z'})
        ..enqueueJson(<String, dynamic>{'now': '2026-03-14T12:32:00Z'});

      await skew.skew();
      clock.advance(const Duration(minutes: 30));
      await skew.skew();

      expect(http.requests, hasLength(2));
    });

    test('reports an unparseable instant instead of throwing', () async {
      // The one place this adapter catches. The alternative is letting a
      // FormatException cross a port boundary and reach a drain that has no
      // way to handle it.
      http.enqueueJson(<String, dynamic>{'now': 'half past four'});

      expect((await skew.skew()).isFailure, isTrue);
    });

    test('reports an offline device as offline', () async {
      http.enqueueFailure(const TransportOffline());

      expect(
        (await skew.skew()).fold((_) => null, (f) => f),
        const SyncOffline(),
      );
    });
  });
}
