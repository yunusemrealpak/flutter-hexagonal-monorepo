@Tags(['unit'])
library;

import 'package:sync_api/sync_api.dart';
import 'package:test/test.dart';

void main() {
  group('isTransient', () {
    test('says yes to everything that could plausibly work later', () {
      const transient = <SyncFailure>[
        SyncOffline(),
        SyncTransportFailed(),
        OutboxUnavailable(),
      ];

      expect(transient.every((failure) => failure.isTransient), isTrue);
    });

    test('says no to everything retrying cannot fix', () {
      const permanent = <SyncFailure>[
        SyncRejected(reason: 'unknown shipment', statusCode: 422),
        SyncConflict(cursor: 'c-9', detail: 'newer write exists'),
        MalformedEntry(field: 'payload', reason: 'is not JSON'),
      ];

      expect(permanent.any((failure) => failure.isTransient), isFalse);
    });

    test('does not call a conflict transient', () {
      // A conflict is neither, on its own — whether trying again helps is the
      // entry's ConflictPolicy's answer. Reporting it as transient here would
      // let the schedule retry a write the server has already decided against,
      // and a serverWins entry would come back every backoff until its
      // attempts ran out.
      const failure = SyncConflict(cursor: 'c-9', detail: 'newer write exists');

      expect(failure.isTransient, isFalse);
    });
  });

  group('the union', () {
    test('is exhaustively matchable', () {
      const failures = <SyncFailure>[
        SyncOffline(),
        SyncTransportFailed(detail: 'reset by peer'),
        SyncRejected(reason: 'unknown shipment', statusCode: 422),
        SyncConflict(cursor: 'c-9', detail: 'newer write exists'),
        OutboxUnavailable(detail: 'database is locked'),
        MalformedEntry(field: 'payload', reason: 'is not JSON'),
      ];

      final described = failures
          .map(
            (failure) => switch (failure) {
              SyncOffline() => 'offline',
              SyncTransportFailed(:final detail) => 'transport: $detail',
              SyncRejected(:final statusCode) => 'rejected: $statusCode',
              SyncConflict(:final cursor) => 'conflict at $cursor',
              OutboxUnavailable() => 'outbox',
              MalformedEntry(:final field) => 'malformed $field',
            },
          )
          .toList();

      expect(described, [
        'offline',
        'transport: reset by peer',
        'rejected: 422',
        'conflict at c-9',
        'outbox',
        'malformed payload',
      ]);
    });
  });
}
