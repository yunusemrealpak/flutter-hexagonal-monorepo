import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:identity_api/identity_api.dart';
import 'package:notifications_api/notifications_api.dart';

import 'close_alerts.dart';
import 'mark_alert_read.dart';
import 'open_alerts.dart';
import 'read_inbox.dart';
import 'record_arriving_alert.dart';

/// The one implementation of `NotificationsFacade`.
///
/// It composes use cases, owns the unread-count stream, and holds the
/// subscription that turns arriving alerts into inbox entries. It holds no
/// rule of its own; every branch below is about *when* to recount, not about
/// what an alert means.
///
/// **Opening alerts is what starts the relay.** A device that cannot be
/// reached has nothing to record, and a subscription started before permission
/// was granted would sit empty and hide the fact. `closeAlertsFor` cancels it,
/// which is what sign-out needs.
///
/// **The count follows one actor**, the one whose alerts are open. A device
/// has one person signed in; a count that tried to serve two would have to
/// carry an actor on every emission and a badge would then have to filter it.
final class NotificationsCoordinator implements NotificationsFacade {
  /// Creates the coordinator over its use cases and the channel it relays
  /// from.
  NotificationsCoordinator({
    required this._read,
    required this._mark,
    required this._record,
    required this._open,
    required this._close,
    required this._channel,
    required this._logger,
  });

  final ReadInbox _read;
  final MarkAlertRead _mark;
  final RecordArrivingAlert _record;
  final OpenAlerts _open;
  final CloseAlerts _close;
  final AlertChannel _channel;
  final Logger _logger;

  final StreamController<int> _unread = StreamController<int>.broadcast();

  StreamSubscription<ArrivingAlert>? _relay;

  @override
  Future<Result<List<InboxEntry>, NotificationsFailure>> inboxOf(
    ActorId actor,
  ) => _read(actor.value);

  @override
  Future<Result<InboxEntry, NotificationsFailure>> markRead(
    ActorId actor,
    NotificationId id,
  ) async {
    final marked = await _mark(
      MarkAlertReadCommand(actorId: actor.value, id: id),
    );
    if (marked case Success()) {
      await _recount(actor.value);
    }
    return marked;
  }

  @override
  Future<Result<void, NotificationsFailure>> openAlertsFor(
    ActorId actor,
  ) async {
    final opened = await _open(actor.value);
    if (opened case Failed()) {
      return opened;
    }

    _relay ??= _channel.arriving().listen(
      (alert) => unawaited(_receive(actor.value, alert)),
    );
    await _recount(actor.value);
    return opened;
  }

  @override
  Future<Result<void, NotificationsFailure>> closeAlertsFor(
    ActorId actor,
  ) async {
    await _relay?.cancel();
    _relay = null;
    return _close(actor.value);
  }

  @override
  Stream<int> unreadCount() => _unread.stream;

  /// Cancels the relay and closes the count stream.
  Future<void> dispose() async {
    await _relay?.cancel();
    _relay = null;
    await _unread.close();
  }

  /// Records one arriving alert.
  ///
  /// There is nobody to return a failure to — an alert arrives from the
  /// network, not from a person — so the failure is logged and the relay stays
  /// alive. A subscription that died on the first storage failure would leave
  /// a courier receiving nothing for the rest of the shift.
  Future<void> _receive(String actorId, ArrivingAlert alert) async {
    final recorded = await _record(
      RecordArrivingAlertCommand(actorId: actorId, alert: alert),
    );

    switch (recorded) {
      case Failed(:final failure):
        _logger.log(
          LogLevel.warning,
          'an alert could not be recorded: $failure',
        );
      case Success():
        await _recount(actorId);
    }
  }

  /// Re-reads the inbox and announces how much of it is unread.
  ///
  /// A re-read rather than an increment. Two devices share an inbox, so a
  /// counter kept in memory here would drift the first time the other one
  /// marked something read — and nothing would say when it had.
  Future<void> _recount(String actorId) async {
    if (_unread.isClosed) {
      return;
    }

    final inbox = await _read(actorId);
    switch (inbox) {
      case Failed(:final failure):
        _logger.log(
          LogLevel.warning,
          'the unread count could not be read: $failure',
        );
      case Success(:final value):
        if (!_unread.isClosed) {
          _unread.add(value.where((entry) => entry.isUnread).length);
        }
    }
  }
}
