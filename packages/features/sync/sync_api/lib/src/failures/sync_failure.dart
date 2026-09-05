import 'package:core_kernel/core_kernel.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_failure.freezed.dart';

/// Everything that can go wrong on a sync port.
///
/// Sealed, so a caller that handles the cases exhaustively keeps compiling
/// only for as long as it still handles all of them.
///
/// The distinction this union exists to make is [isTransient]. A retry
/// schedule that cannot tell "the tunnel ate the request" from "the server
/// says this command is nonsense" does one of two harmful things: it retries
/// the nonsense until the queue head is permanently stuck, or it drops the
/// tunnel case and loses a delivery that actually happened. Both are the same
/// bug — a missing distinction — and both are why the answer lives on the
/// failure type rather than in whichever use case last thought about it.
@freezed
sealed class SyncFailure extends Failure with _$SyncFailure {
  const SyncFailure._();

  /// The device has no usable connection.
  ///
  /// Transient by definition, and the most common failure in this feature by
  /// a wide margin: an offline-first product spends its day here.
  const factory SyncFailure.offline() = SyncOffline;

  /// The request left and did not come back.
  ///
  /// A timeout, a reset connection, a 5xx. Nothing is known about whether the
  /// server acted on it, which is exactly why an entry keeps its identifier
  /// across retries — the second attempt has to be recognisable as the same
  /// work.
  const factory SyncFailure.transportFailed({String? detail}) =
      SyncTransportFailed;

  /// The server understood the command and refused it.
  ///
  /// Permanent. Retrying a 4xx produces the same 4xx until somebody looks at
  /// it, so the entry goes to the manual-review queue instead of holding up
  /// everything queued behind it.
  const factory SyncFailure.rejected({
    required String reason,
    int? statusCode,
  }) = SyncRejected;

  /// The server has moved on from the position this device last saw.
  ///
  /// Carries the server's [cursor] so the caller can resume from it. What
  /// happens next is not this failure's decision: the entry's `ConflictPolicy`
  /// says whether the device's write wins, the server's does, or a person has
  /// to look.
  const factory SyncFailure.conflict({
    required String cursor,
    required String detail,
  }) = SyncConflict;

  /// The outbox itself could not be read or written.
  ///
  /// Transient — a locked database usually unlocks — but it is the one failure
  /// that means the queue cannot be trusted to remember, so a drain stops
  /// rather than continuing against a store that may be dropping writes.
  const factory SyncFailure.outboxUnavailable({String? detail}) =
      OutboxUnavailable;

  /// A queued entry could not be read back in the shape it was stored in.
  const factory SyncFailure.malformedEntry({
    required String field,
    required String reason,
  }) = MalformedEntry;

  /// Whether trying again later could plausibly succeed.
  ///
  /// The single question the retry schedule asks. A permanent failure is not
  /// retried at all: it is blocked for review, where a person decides, and the
  /// entries behind it keep draining.
  bool get isTransient => switch (this) {
    SyncOffline() => true,
    SyncTransportFailed() => true,
    OutboxUnavailable() => true,
    SyncRejected() => false,
    // A conflict is neither, on its own. Whether trying again can help is the
    // ConflictPolicy's answer, not the failure's, and reporting it as
    // transient here would let the schedule retry a write the server has
    // already decided against.
    SyncConflict() => false,
    MalformedEntry() => false,
  };
}
