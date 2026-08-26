import 'package:sync_api/sync_api.dart';
import 'package:test/test.dart';

import 'outbox_entry_builder.dart';

/// The behaviour every `CommandTransportPort` has to have.
///
/// Smaller than the outbox kit, because the port is smaller: one method, and
/// only the parts of its behaviour that are reachable *through* it. Provoking
/// a timeout or a 409 is something only one implementation can arrange, so
/// those live in each implementation's own tests — a suite that needed a back
/// door would stop being runnable against the other implementation, which is
/// the whole point of having one suite.
///
/// What is left is nonetheless the property that matters most in this feature:
/// **the same envelope sent twice produces one piece of work.** A transport
/// that failed that would turn every lost acknowledgement into a second
/// payment taken at a door.
///
/// [createTransport] must return a fresh transport on every call, and
/// [acceptedCount] must report how many distinct pieces of work it ended up
/// holding — the one thing the port itself cannot be asked.
void runCommandTransportContract(
  CommandTransportPort Function() createTransport, {
  required int Function(CommandTransportPort transport) acceptedCount,
}) {
  group('CommandTransportPort contract', () {
    late CommandTransportPort transport;

    setUp(() => transport = createTransport());

    SyncEnvelope envelopeFor(String id, {int attempt = 1}) {
      var entry = OutboxEntryBuilder().withId(id).build();
      for (var i = 1; i < attempt; i++) {
        entry = entry.attempted(
          at: OutboxEntryBuilder.defaultQueuedAt,
          backoff: const Duration(seconds: 1),
        );
      }
      return entry.envelopeFor(cursor: SyncCursor.beginning);
    }

    test('accepts an envelope and reports a position', () async {
      final sent = await transport.send(envelopeFor('e-1'));

      expect(sent.isSuccess, isTrue);
    });

    test('moves the position on when it accepts new work', () async {
      final first = await transport.send(envelopeFor('e-1'));
      final second = await transport.send(envelopeFor('e-2'));

      expect(
        first.fold((c) => c, (f) => throw StateError('$f')),
        isNot(second.fold((c) => c, (f) => throw StateError('$f'))),
        reason:
            'a device that never advanced its cursor would report a '
            'conflict against its own previous write',
      );
    });

    test('leaves the beginning behind after the first acceptance', () async {
      final sent = await transport.send(envelopeFor('e-1'));
      final cursor = sent.fold((c) => c, (f) => throw StateError('$f'));

      expect(cursor.isBeginning, isFalse);
    });

    test('the same entry sent twice is one piece of work', () async {
      // The property this kit exists for. An acknowledgement that was lost on
      // the way back is indistinguishable from one that never happened, so a
      // retry is guaranteed and has to be free.
      await transport.send(envelopeFor('e-1'));
      await transport.send(envelopeFor('e-1', attempt: 2));

      expect(acceptedCount(transport), 1);
    });

    test('a retry is acknowledged with the position it first got', () async {
      final first = await transport.send(envelopeFor('e-1'));
      final retry = await transport.send(envelopeFor('e-1', attempt: 2));

      expect(
        retry.fold((c) => c, (f) => throw StateError('$f')),
        first.fold((c) => c, (f) => throw StateError('$f')),
      );
    });

    test('different entries are different work', () async {
      await transport.send(envelopeFor('e-1'));
      await transport.send(envelopeFor('e-2'));

      expect(acceptedCount(transport), 2);
    });
  });
}
