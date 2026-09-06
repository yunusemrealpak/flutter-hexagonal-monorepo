import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:flutter/foundation.dart';
import 'package:sync_api/sync_api.dart';

import 'review_queue_state.dart';

/// Drives the manual-review screen and the queue badge beside it.
///
/// It holds one port — `SyncFacade` — and no implementations. Whether the
/// queue behind it is drift-backed or in memory, and whether the transport is
/// HTTP or a fake, is decided by whichever app composed it; this package
/// cannot depend on `sync_application` or `sync_infrastructure` and does not
/// want to.
///
/// A `ChangeNotifier` rather than a bloc, and that is a deliberate
/// non-decision: no state management library is a dependency of this workspace
/// yet, and introducing one here would make every feature inherit the choice.
/// The state type beside this class is the part that matters — swapping in a
/// bloc changes this file and nothing else, because a widget renders
/// `ReviewQueueState` and does not know what produced it.
final class ReviewQueueController extends ChangeNotifier {
  /// Creates the controller over the facade.
  ReviewQueueController({required this._sync});

  final SyncFacade _sync;

  StreamSubscription<SyncStatus>? _statuses;

  ReviewQueueState _state = const ReviewIdle();

  SyncStatus _status = const SyncStatus.idle();

  /// What the screen should be showing.
  ReviewQueueState get state => _state;

  /// What the badge should be showing.
  ///
  /// Separate from [state], because the two answer different questions and
  /// change at different times: the badge follows the queue continuously and
  /// the list is read when somebody opens the screen. Folding the status into
  /// the state union would make every status change redraw a list that has not
  /// changed.
  SyncStatus get status => _status;

  /// Starts following the queue's status.
  ///
  /// Implementations of `statusChanges` emit the current status on
  /// subscription, so the badge is right from the first frame rather than
  /// blank until something happens.
  void watch() {
    _statuses ??= _sync.statusChanges().listen((status) {
      _status = status;
      notifyListeners();
    });
  }

  /// Reads the work a person has to resolve.
  Future<void> load() async {
    _emit(const ReviewLoading());

    final queue = await _sync.awaitingReview();
    _emit(
      switch (queue) {
        Success(value: final entries) => ReviewReady(entries),
        Failed(:final failure) => ReviewFailed(failure),
      },
    );
  }

  /// Puts one blocked entry back in the queue and refreshes the list.
  ///
  /// The refresh is a re-read rather than a local removal. Two people can be
  /// looking at the same review queue, and a list that removed the row
  /// optimistically would disagree with the store the moment the other person
  /// resolved something.
  Future<void> retry(OutboxEntryId id) async {
    final resolved = await _sync.retry(id);
    if (resolved case Failed(:final failure)) {
      _emit(ReviewFailed(failure));
      return;
    }
    await load();
  }

  @override
  void dispose() {
    unawaited(_statuses?.cancel());
    super.dispose();
  }

  void _emit(ReviewQueueState next) {
    _state = next;
    notifyListeners();
  }
}
