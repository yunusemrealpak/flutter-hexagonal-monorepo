import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:notifications_api/notifications_api.dart';

/// Which alert, in whose inbox.
final class MarkAlertReadCommand {
  /// Creates the command.
  const MarkAlertReadCommand({required this.actorId, required this.id});

  /// Whose inbox, as the store spells it.
  final String actorId;

  /// Which alert.
  final NotificationId id;
}

/// Records that somebody has seen an alert.
///
/// The instant comes from a `Clock` — rule A1 — which is what lets the test
/// below assert on an exact timestamp instead of a range.
///
/// Marking an alert that is already read succeeds and stores nothing. That is
/// `InboxEntry.readAtInstant`'s idempotence, and this use case leans on it
/// rather than re-deciding: two devices show one inbox, and the second tap is
/// the same fact arriving later.
final class MarkAlertRead
    implements
        UseCase<
          MarkAlertReadCommand,
          Result<InboxEntry, NotificationsFailure>
        > {
  /// Creates the use case.
  const MarkAlertRead({required this._inbox, required this._clock});

  final InboxStore _inbox;
  final Clock _clock;

  @override
  Future<Result<InboxEntry, NotificationsFailure>> call(
    MarkAlertReadCommand command,
  ) async {
    final read = await _inbox.entriesFor(command.actorId);
    if (read case Failed(:final failure)) {
      return Failed(failure);
    }

    final entries =
        (read as Success<List<InboxEntry>, NotificationsFailure>).value;
    final index = entries.indexWhere((entry) => entry.id == command.id);
    if (index < 0) {
      return Failed(NotificationMissing(command.id.value));
    }

    final entry = entries[index];
    if (!entry.isUnread) {
      return Success(entry);
    }

    final marked = entry.readAtInstant(_clock.now());
    final written = await _inbox.update(command.actorId, marked);

    return switch (written) {
      Failed(:final failure) => Failed(failure),
      Success() => Success(marked),
    };
  }
}
