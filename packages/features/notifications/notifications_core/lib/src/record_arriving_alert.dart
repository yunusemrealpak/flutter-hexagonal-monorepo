import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:notifications_api/notifications_api.dart';

/// An alert that has arrived, and whose inbox it belongs in.
final class RecordArrivingAlertCommand {
  /// Creates the command.
  const RecordArrivingAlertCommand({
    required this.actorId,
    required this.alert,
  });

  /// Whose inbox, as the store spells it.
  final String actorId;

  /// What arrived.
  final ArrivingAlert alert;
}

/// Puts an arriving alert in somebody's inbox.
///
/// Two ports and two rules:
///
/// **The identifier.** An alert the sender identified keeps that identifier,
/// which is what makes the second copy of an at-least-once delivery
/// recognisable — `InboxStore.put` then drops it. An alert with no identifier
/// gets one from `IdGenerator`, and two copies of *that* alert are genuinely
/// indistinguishable; there is no honest way to deduplicate what the sender
/// did not label.
///
/// **The instant.** From a `Clock`, never `DateTime.now()` — rule A1. It is
/// the moment of *receipt*, which is not the moment the sender sent: push can
/// be delivered long after, to a phone that was off, and an inbox sorted by
/// send time would put an alert a courier has never seen below one they read
/// this morning.
final class RecordArrivingAlert
    implements
        UseCase<
          RecordArrivingAlertCommand,
          Result<InboxEntry, NotificationsFailure>
        > {
  /// Creates the use case.
  const RecordArrivingAlert({
    required this._inbox,
    required this._clock,
    required this._ids,
  });

  final InboxStore _inbox;
  final Clock _clock;
  final IdGenerator _ids;

  @override
  Future<Result<InboxEntry, NotificationsFailure>> call(
    RecordArrivingAlertCommand command,
  ) async {
    final alert = command.alert;

    final built = NotificationId.parse(alert.externalId ?? _ids.newId())
        .flatMap(
          (id) => InboxEntry.arriving(
            id: id,
            kind: alert.kind,
            subject: alert.subject,
            receivedAt: _clock.now(),
            arguments: alert.arguments,
          ),
        );
    if (built case Failed(:final failure)) {
      return Failed(failure);
    }

    final entry = (built as Success<InboxEntry, NotificationsFailure>).value;
    final stored = await _inbox.put(command.actorId, entry);

    return switch (stored) {
      Failed(:final failure) => Failed(failure),
      Success() => Success(entry),
    };
  }
}
