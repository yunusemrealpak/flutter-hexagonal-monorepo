import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_status.freezed.dart';

/// What the outbox is doing, as a screen would need to say it.
///
/// A closed union rather than a flat object with `isDraining`, `pending` and
/// `nextAttemptAt` on it. The flat shape lets a caller be handed something
/// that is draining *and* waiting for network *and* has a retry scheduled, and
/// the day two of those are set at once nobody can say what the badge in the
/// corner should read. Here the compiler answers it.
///
/// Every case carries [pending] so that a caller can render a count without
/// first working out which state it is in. That is the one piece of
/// information every state genuinely has.
@freezed
sealed class SyncStatus with _$SyncStatus {
  const SyncStatus._();

  /// Nothing is queued and nothing is running.
  const factory SyncStatus.idle() = SyncIdle;

  /// A drain is in progress.
  const factory SyncStatus.draining({required int pending}) = SyncDraining;

  /// There is work, and no connection to carry it.
  ///
  /// Distinct from [SyncWaitingToRetry] because the two mean different things
  /// to the person holding the device: one is "you are in a basement" and the
  /// other is "the server said no, we are trying again shortly". Collapsing
  /// them into "not synced" is what makes a courier restart an app that was
  /// working correctly.
  const factory SyncStatus.waitingForNetwork({required int pending}) =
      SyncWaitingForNetwork;

  /// There is work, a connection, and a backoff still running.
  const factory SyncStatus.waitingToRetry({
    required int pending,
    required DateTime nextAttemptAt,
  }) = SyncWaitingToRetry;

  /// Some work cannot proceed without a person.
  ///
  /// [pending] counts everything still queued and [needingReview] the subset
  /// that is blocked, so a screen can say "12 waiting, 2 need attention"
  /// without a second query. A blocked entry does not stop the rest: this
  /// state is reported while the others keep draining.
  const factory SyncStatus.blocked({
    required int pending,
    required int needingReview,
  }) = SyncBlocked;

  /// How much work is queued, whatever state the queue is in.
  int get pending => switch (this) {
    SyncIdle() => 0,
    SyncDraining(:final pending) => pending,
    SyncWaitingForNetwork(:final pending) => pending,
    SyncWaitingToRetry(:final pending) => pending,
    SyncBlocked(:final pending) => pending,
  };

  /// How much of it a person has to look at.
  int get needingReview => switch (this) {
    SyncBlocked(:final needingReview) => needingReview,
    _ => 0,
  };
}
