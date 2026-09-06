import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notifications_api/notifications_api.dart';

import 'unread_event.dart';
import 'unread_state.dart';

/// Follows how many alerts are waiting.
///
/// **A bloc that exists to hold a subscription**, and the shape it uses is the
/// one `Bloc` provides for exactly that: `emit.onEach` inside a handler. The
/// handler does not return until the stream ends or the emitter is cancelled,
/// which is what makes the subscription the bloc's rather than a field's.
///
/// That replaces three things the `ChangeNotifier` had to do by hand: a
/// nullable `StreamSubscription` field, a `_counts ??=` guard so that watching
/// twice did not open two subscriptions, and a `dispose` override to cancel
/// it. `restartable()` supplies the first two — a second [UnreadWatched]
/// cancels the first emitter before starting again — and `close()` supplies
/// the third, because closing a bloc cancels its emitters.
///
/// **It is separate from `InboxBloc` because it is separate state.** The count
/// is drawn on screens that have nothing else to do with notifications — a
/// route list, a shipment detail — and folding it into the inbox's state would
/// mean every arriving alert emitted a state carrying a list nobody is looking
/// at, and every app that wanted a badge had to build an inbox to get one.
final class UnreadBloc extends Bloc<UnreadEvent, UnreadState> {
  /// Creates the bloc.
  UnreadBloc({required this._notifications}) : super(const UnreadUnknown()) {
    on<UnreadWatched>(_onWatched, transformer: restartable());
  }

  final NotificationsFacade _notifications;

  Future<void> _onWatched(UnreadWatched event, Emitter<UnreadState> emit) =>
      emit.onEach<int>(
        _notifications.unreadCount(),
        onData: (count) => emit(UnreadCount(count)),
      );
}
