import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_api/sync_api.dart';

import 'sync_status_event.dart';

/// Follows the queue, for the badge that every screen in a courier app draws.
///
/// **Its own bloc rather than a field on the review screen's**, and the split
/// is a lifetime rather than a preference. A badge follows the queue for as
/// long as an app is running and belongs above the router; a review list is
/// read when somebody opens a route and dies with it. One object driving both
/// meant a status tick redrew a list that had not changed — which the code it
/// replaces admitted in a comment, and worked around by holding the status
/// outside its own state where no widget could subscribe to it separately.
///
/// **The state is `SyncStatus` itself.** There is no idle case to add and no
/// failure branch to model: `statusChanges()` cannot fail, and its
/// implementations emit the current status on subscription, so the badge is
/// right from the first frame rather than blank until something happens.
/// `SyncStatus.idle()` is the honest value to start from — a queue nobody has
/// heard from yet is a queue with nothing in it.
///
/// `restartable()` with `emit.onEach` replaces a nullable `StreamSubscription`,
/// the `??=` that stopped a second `watch()` opening a second one, and a
/// `dispose` override. A second [SyncStatusWatched] cancels the first
/// subscription instead of leaking it.
final class SyncStatusBloc extends Bloc<SyncStatusEvent, SyncStatus> {
  /// Creates the bloc over the facade.
  SyncStatusBloc({required this._sync}) : super(const SyncStatus.idle()) {
    on<SyncStatusWatched>(_onWatched, transformer: restartable());
  }

  final SyncFacade _sync;

  Future<void> _onWatched(SyncStatusWatched event, Emitter<SyncStatus> emit) =>
      emit.onEach<SyncStatus>(_sync.statusChanges(), onData: emit.call);
}
