import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:sync_api/sync_api.dart';

/// What a caller wants queued, and what should happen if the server has moved
/// on by the time it lands.
typedef QueueRequest = ({SyncCommand command, ConflictPolicy policy});

/// Writes one piece of work into the outbox and returns immediately.
///
/// The method deliberately does not attempt delivery. A courier who completes
/// a delivery in a basement gets the same answer as one who completes it in a
/// yard with five bars: the work is recorded, and the queue's job starts
/// afterwards. A use case that awaited the network here would be an
/// offline-first product that only looks like one.
///
/// Both ambient sources it needs are ports. [IdGenerator] produces the
/// identifier — which is also the handle the server de-duplicates on, so it
/// has to exist before anything has seen a server — and [Clock] produces the
/// instant. Rules A1 and A3, at the two places this feature would otherwise
/// break them.
final class EnqueueCommand
    implements UseCase<QueueRequest, Result<OutboxEntry, SyncFailure>> {
  /// Creates the use case.
  const EnqueueCommand({
    required this._store,
    required this._clock,
    required this._ids,
    required this._logger,
  });

  final OutboxStore _store;
  final Clock _clock;
  final IdGenerator _ids;
  final Logger _logger;

  @override
  Future<Result<OutboxEntry, SyncFailure>> call(QueueRequest request) async {
    // A generator that returns an empty string is a misconfigured composition
    // root, and it is reported rather than thrown: a use case that threw here
    // would put an exception on the caller's path for a mistake made in an
    // app's wiring, which is invariant 1.2.9 read the other way round.
    final OutboxEntryId id;
    switch (OutboxEntryId.parse(_ids.newId())) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        id = value;
    }

    final entry = OutboxEntry.queued(
      id: id,
      command: request.command,
      policy: request.policy,
      at: _clock.now(),
    );

    final written = await _store.put(entry);
    if (written case Failed(:final failure)) {
      // The one failure a caller genuinely has to hear about. Everything else
      // in this feature is "not yet"; this is "the device could not write it
      // down", and the feature that called has to decide whether its own
      // operation succeeded without a durable record of it.
      _logger.error(
        'could not queue work for sync',
        context: {'type': request.command.type, 'failure': '$failure'},
      );
      return Failed(failure);
    }

    _logger.info(
      'queued work for sync',
      context: {'type': entry.type, 'entry': entry.id.value},
    );
    return Success(entry);
  }
}
