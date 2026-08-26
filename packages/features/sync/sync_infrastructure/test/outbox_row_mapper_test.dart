@Tags(['unit'])
library;

import 'package:storage_drift/storage_drift.dart' as db;
import 'package:sync_api/sync_api.dart';
import 'package:sync_infrastructure/sync_infrastructure.dart';
import 'package:sync_testing/sync_testing.dart';
import 'package:test/test.dart';

void main() {
  final queuedAt = DateTime.utc(2026, 3, 14, 12);

  OutboxEntry entry({
    String type = 'delivery.completeAttempt',
    ConflictPolicy policy = const ConflictPolicy.lastWriteWins(),
  }) => OutboxEntryBuilder()
      .withId('e-1')
      .ofType(type)
      .under(policy)
      .queuedAt(queuedAt)
      .build();

  group('the routing key', () {
    test('splits into a feature and an operation on the way down', () {
      // Two columns because a person reading a stuck queue wants to filter by
      // feature; one routing key because that is what a composition root maps
      // to a handler.
      final row = OutboxRowMapper.toRow(entry());

      expect(row.feature, 'delivery');
      expect(row.operation, 'completeAttempt');
    });

    test('splits on the first dot, not the last', () {
      final row = OutboxRowMapper.toRow(entry(type: 'payments.cash.collect'));

      expect(row.feature, 'payments');
      expect(row.operation, 'cash.collect');
    });

    test('files a key with no dot rather than refusing it', () {
      // A row that cannot be stored is work that has been lost, which is worse
      // than a row filed under the wrong heading.
      final row = OutboxRowMapper.toRow(entry(type: 'legacy'));

      expect(row.feature, OutboxRowMapper.unknownFeature);
      expect(row.operation, 'legacy');
    });

    test('comes back exactly as it went in', () {
      for (final type in [
        'delivery.completeAttempt',
        'payments.cash.collect',
        'legacy',
      ]) {
        final round = OutboxRowMapper.toDomain(
          OutboxRowMapper.toRow(entry(type: type)),
        );

        expect(
          round.fold((e) => e.type, (f) => throw StateError('$f')),
          type,
        );
      }
    });
  });

  group('the conflict policy', () {
    test('round-trips every case', () {
      const policies = <ConflictPolicy>[
        ConflictPolicy.lastWriteWins(),
        ConflictPolicy.serverWins(),
        ConflictPolicy.manualReview(),
      ];

      for (final policy in policies) {
        expect(
          OutboxRowMapper.policyFrom(OutboxRowMapper.policyName(policy)),
          policy,
        );
      }
    });

    test('reads an unrecognised value as the one that keeps the work', () {
      // A downgrade, a hand-edited database, a name a newer release invented.
      // lastWriteWins is the only case that neither discards the device's work
      // nor demands a person's attention.
      expect(
        OutboxRowMapper.policyFrom('somethingNobodyShipped'),
        const ConflictPolicy.lastWriteWins(),
      );
    });
  });

  group('the rest of the row', () {
    test('carries the schedule and the block reason across', () {
      final blocked = entry()
          .attempted(at: queuedAt, backoff: const Duration(minutes: 4))
          .blocked('rejected: unknown shipment');

      final round = OutboxRowMapper.toDomain(OutboxRowMapper.toRow(blocked));
      final read = round.fold((e) => e, (f) => throw StateError('$f'));

      expect(read.attempts, 1);
      expect(read.lastAttemptAt, queuedAt);
      expect(read.nextAttemptAt, queuedAt.add(const Duration(minutes: 4)));
      expect(read.blockedReason, 'rejected: unknown shipment');
      expect(read.isBlocked, isTrue);
    });

    test('leaves the payload untouched', () {
      // The one thing sync is not entitled to interpret. A mapper that
      // normalised it would corrupt a feature's body without being able to
      // tell.
      const body = '{"proof":"sig-1","note":"left with neighbour, 3B"}';
      final row = OutboxRowMapper.toRow(
        OutboxEntryBuilder()
            .withId('e-1')
            .of(const TestSyncCommand(payload: body))
            .build(),
      );

      expect(row.payload, body);
    });

    test('reports a row whose identifier cannot be read', () {
      final broken = db.OutboxEntry(
        id: '   ',
        feature: 'delivery',
        operation: 'completeAttempt',
        payload: '{}',
        createdAt: queuedAt,
        attemptCount: 0,
        conflictPolicy: 'lastWriteWins',
      );

      expect(OutboxRowMapper.toDomain(broken).isFailure, isTrue);
    });
  });
}
