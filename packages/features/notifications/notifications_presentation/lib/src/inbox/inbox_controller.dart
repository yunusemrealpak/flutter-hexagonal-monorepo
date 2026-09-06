import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:flutter/foundation.dart';
import 'package:identity_api/identity_api.dart';
import 'package:notifications_api/notifications_api.dart';

import 'inbox_state.dart';

/// Drives the inbox screen and the badge beside it.
///
/// It holds one port — `NotificationsFacade` — and no implementation. Whether
/// the alerts behind it arrived by push or were written by a test is decided
/// by whichever app composed it.
final class InboxController extends ChangeNotifier {
  /// Creates the controller for one actor.
  InboxController({required this._notifications, required this._actor});

  final NotificationsFacade _notifications;
  final ActorId _actor;

  StreamSubscription<int>? _counts;

  InboxState _state = const InboxIdle();

  int _unread = 0;

  /// What the screen should be showing.
  InboxState get state => _state;

  /// What the badge should be showing.
  ///
  /// Separate from [state], because the two answer different questions and
  /// change at different times: the badge follows the count continuously and
  /// is drawn on every screen, while the list is read when somebody opens the
  /// inbox. Folding the count into the state union would make every arriving
  /// alert redraw a list nobody is looking at.
  int get unread => _unread;

  /// Starts following the unread count.
  void watch() {
    _counts ??= _notifications.unreadCount().listen((count) {
      _unread = count;
      notifyListeners();
    });
  }

  /// Reads the inbox.
  Future<void> load() async {
    _emit(const InboxLoading());

    final read = await _notifications.inboxOf(_actor);
    _emit(
      switch (read) {
        Success(value: final entries) => InboxReady(entries),
        Failed(:final failure) => InboxFailed(failure),
      },
    );
  }

  /// Marks one alert read and refreshes the list.
  ///
  /// The refresh is a re-read rather than a local edit, for the same reason
  /// the count is: two devices can be looking at one inbox, and a list that
  /// updated the row optimistically would disagree with the store the moment
  /// the other device cleared it.
  Future<void> markRead(NotificationId id) async {
    final marked = await _notifications.markRead(_actor, id);
    if (marked case Failed(:final failure)) {
      _emit(InboxFailed(failure));
      return;
    }
    await load();
  }

  @override
  void dispose() {
    unawaited(_counts?.cancel());
    super.dispose();
  }

  void _emit(InboxState next) {
    _state = next;
    notifyListeners();
  }
}
