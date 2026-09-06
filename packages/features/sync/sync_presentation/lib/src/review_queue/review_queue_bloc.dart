import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core_kernel/core_kernel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_api/sync_api.dart';

import 'review_queue_event.dart';
import 'review_queue_state.dart';

/// Drives the manual-review screen.
///
/// It holds one port — `SyncFacade` — and no implementations. Whether the
/// queue behind it is drift-backed or in memory, and whether the transport is
/// HTTP or a fake, is decided by whichever app composed it; this package
/// cannot depend on `sync_application` or `sync_infrastructure` and does not
/// want to.
///
/// **The status is not here, and moving it out is what this conversion
/// bought.** One `ChangeNotifier` drove both this screen and the badge beside
/// it, so it carried two independent facts and had one notification to report
/// them with: every tick of a draining queue redrew a list that had not
/// changed. The two are now two blocs, because they have two lifetimes — a
/// badge follows the queue for as long as an app is running, and a list is
/// read when somebody opens a route. See `SyncStatusBloc`.
///
/// **Reading is `restartable()`**: a newer read of the queue makes an older
/// one worthless, and this is a query with no side effect.
///
/// **Retrying is `sequential()`**, which is the interesting one. Two blocked
/// entries a person resolved are two different things that must both happen —
/// so `droppable()`, which would silently lose the second, is wrong. They must
/// not overlap either: each retry is followed by a re-read, and under
/// `concurrent()` the older read can answer last and put a row back on screen
/// that the newer one had already seen resolved.
final class ReviewQueueBloc extends Bloc<ReviewQueueEvent, ReviewQueueState> {
  /// Creates the bloc over the facade.
  ReviewQueueBloc({required this._sync}) : super(const ReviewIdle()) {
    on<ReviewRequested>(_onRequested, transformer: restartable());
    on<EntryRetried>(_onRetried, transformer: sequential());
  }

  final SyncFacade _sync;

  Future<void> _onRequested(
    ReviewRequested event,
    Emitter<ReviewQueueState> emit,
  ) async {
    emit(const ReviewLoading());
    emit(_settled(await _sync.awaitingReview()));
  }

  /// Puts one blocked entry back in the queue and re-reads the list.
  ///
  /// The refresh is a re-read rather than a local removal. Two people can be
  /// looking at the same review queue, and a list that removed the row
  /// optimistically would disagree with the store the moment the other person
  /// resolved something.
  Future<void> _onRetried(
    EntryRetried event,
    Emitter<ReviewQueueState> emit,
  ) async {
    final resolved = await _sync.retry(event.id);
    if (resolved case Failed(:final failure)) {
      emit(ReviewFailed(failure));
      return;
    }

    emit(_settled(await _sync.awaitingReview()));
  }

  ReviewQueueState _settled(
    Result<List<OutboxEntry>, SyncFailure> queue,
  ) => switch (queue) {
    Success(value: final entries) => ReviewReady(entries),
    Failed(:final failure) => ReviewFailed(failure),
  };
}
