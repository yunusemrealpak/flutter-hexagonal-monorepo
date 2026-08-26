@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:sync_api/sync_api.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  group('OutboxEntryId', () {
    test('trims and accepts', () {
      expect(unwrap(OutboxEntryId.parse('  entry-1 ')).value, 'entry-1');
    });

    test('refuses an empty identifier', () {
      expect(
        OutboxEntryId.parse('   '),
        const Failed<OutboxEntryId, SyncFailure>(
          MalformedEntry(field: 'id', reason: 'is empty'),
        ),
      );
    });

    test('is not interchangeable with another wrapped string', () {
      // runtimeType participates in equality, which is what makes wrapping a
      // String worth the ceremony: an entry id cannot be passed where a cursor
      // is meant, even though both are strings on the wire.
      expect(entryId('c-1'), isNot(const SyncCursor('c-1')));
    });
  });

  group('SyncCursor', () {
    test('a fresh device is at the beginning', () {
      expect(SyncCursor.beginning.isBeginning, isTrue);
      expect(SyncCursor.beginning.value, isEmpty);
    });

    test('a server token is not', () {
      expect(const SyncCursor('c-9').isBeginning, isFalse);
    });

    test('two cursors with the same token are the same position', () {
      expect(const SyncCursor('c-9'), const SyncCursor('c-9'));
    });
  });

  group('ConflictPolicy', () {
    test('only lastWriteWins tries again after a conflict', () {
      expect(const ConflictPolicy.lastWriteWins().retriesAfterConflict, isTrue);
      expect(const ConflictPolicy.serverWins().retriesAfterConflict, isFalse);
      expect(const ConflictPolicy.manualReview().retriesAfterConflict, isFalse);
    });

    test('is exhaustively matchable', () {
      const policies = <ConflictPolicy>[
        ConflictPolicy.lastWriteWins(),
        ConflictPolicy.serverWins(),
        ConflictPolicy.manualReview(),
      ];

      final described = policies
          .map(
            (policy) => switch (policy) {
              LastWriteWins() => 'resend',
              ServerWins() => 'drop',
              ManualReview() => 'block',
            },
          )
          .toList();

      expect(described, ['resend', 'drop', 'block']);
    });
  });

  group('SyncStatus', () {
    test('every case can be asked how much is queued', () {
      expect(const SyncStatus.idle().pending, 0);
      expect(const SyncStatus.draining(pending: 3).pending, 3);
      expect(const SyncStatus.waitingForNetwork(pending: 4).pending, 4);
      expect(
        SyncStatus.waitingToRetry(pending: 5, nextAttemptAt: noon).pending,
        5,
      );
      expect(
        const SyncStatus.blocked(pending: 6, needingReview: 2).pending,
        6,
      );
    });

    test('only the blocked case has anything for a person to do', () {
      expect(
        const SyncStatus.blocked(pending: 6, needingReview: 2).needingReview,
        2,
      );
      expect(const SyncStatus.draining(pending: 3).needingReview, 0);
    });

    test('separates no signal from a running backoff', () {
      // The two mean different things to the person holding the device, and
      // collapsing them into "not synced" is what makes a courier restart an
      // app that is working correctly.
      expect(
        const SyncStatus.waitingForNetwork(pending: 1),
        isNot(SyncStatus.waitingToRetry(pending: 1, nextAttemptAt: noon)),
      );
    });
  });
}
