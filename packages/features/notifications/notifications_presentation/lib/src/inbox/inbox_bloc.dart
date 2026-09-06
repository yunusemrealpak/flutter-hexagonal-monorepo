import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core_kernel/core_kernel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:identity_api/identity_api.dart';
import 'package:notifications_api/notifications_api.dart';

import 'inbox_event.dart';
import 'inbox_state.dart';

/// Drives the inbox screen.
///
/// It holds one port — `NotificationsFacade` — and no implementation. Whether
/// the alerts behind it arrived by push or were written by a test is decided
/// by whichever app composed it.
///
/// **The unread count is not here, and that is the point of the split.** It
/// lives in `UnreadBloc`, one folder over, because it answers a different
/// question and changes at a different rate: the badge follows the count
/// continuously and is drawn on screens that have nothing else to do with
/// notifications, while this list is read when somebody opens the inbox.
///
/// `restartable()` on the read and `sequential()` on marking read. The second
/// is the same reasoning as `incidents`: every one of those is a *different*
/// alert being opened, so none may be dropped, and two of them re-reading the
/// inbox at once can land out of order.
final class InboxBloc extends Bloc<InboxEvent, InboxState> {
  /// Creates the bloc for one actor.
  InboxBloc({required this._notifications, required this._actor})
    : super(const InboxIdle()) {
    on<InboxRequested>(_onRequested, transformer: restartable());
    on<AlertMarkedRead>(_onMarkedRead, transformer: sequential());
  }

  final NotificationsFacade _notifications;
  final ActorId _actor;

  Future<void> _onRequested(
    InboxRequested event,
    Emitter<InboxState> emit,
  ) async {
    emit(const InboxLoading());
    await _read(emit);
  }

  /// Marks one alert read and re-reads the list.
  ///
  /// A re-read rather than a local edit: two devices can be looking at one
  /// inbox, and a row updated optimistically would disagree with the store the
  /// moment the other device cleared it.
  Future<void> _onMarkedRead(
    AlertMarkedRead event,
    Emitter<InboxState> emit,
  ) async {
    final marked = await _notifications.markRead(_actor, event.id);
    if (marked case Failed(:final failure)) {
      emit(InboxFailed(failure));
      return;
    }
    await _read(emit);
  }

  Future<void> _read(Emitter<InboxState> emit) async {
    emit(
      switch (await _notifications.inboxOf(_actor)) {
        Success(value: final entries) => InboxReady(entries),
        Failed(:final failure) => InboxFailed(failure),
      },
    );
  }
}
