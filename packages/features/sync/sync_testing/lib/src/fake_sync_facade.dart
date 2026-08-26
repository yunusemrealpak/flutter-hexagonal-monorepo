import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:sync_api/sync_api.dart';

import 'outbox_entry_builder.dart';

/// A `SyncFacade` that really queues, for the features that write through it.
///
/// It belongs here rather than in each feature's own tests for the reason a
/// fake always belongs beside its contract: `delivery_application` and
/// `payments_application` both enqueue, both need to assert on what was
/// queued, and two hand-written stubs would drift apart the first time
/// `SyncFacade` grew a method.
///
/// **It never decodes a payload**, and could not — the same constraint the
/// real queue lives under. What it records is what `sync` records: a routing
/// key and a string. A test that wants to know a delivery was queued asserts
/// on the type; a test that wants to know *what* was queued asserts on the
/// command object it handed in, through [queued].
///
/// Enqueueing does not drain. That is the port's promise — a use case that
/// queued and then waited for the network would be an offline-first product
/// that is not — and a fake that delivered eagerly would let a caller depend
/// on something the real one never does.
final class FakeSyncFacade implements SyncFacade {
  /// The commands this queue was handed, oldest first.
  final List<SyncCommand> queued = [];

  /// The policies they were queued under, in the same order.
  final List<ConflictPolicy> policies = [];

  final StreamController<SyncStatus> _statuses =
      StreamController<SyncStatus>.broadcast();
  final List<OutboxEntry> _entries = [];
  final List<SyncFailure> _queuedFailures = [];

  var _minted = 0;

  /// Makes the next call return [failure].
  ///
  /// The case worth using it for is a full or unreadable outbox: a courier's
  /// proof that could not be queued is a proof that exists only in memory, and
  /// a use case that reported success anyway would be lying about it.
  void failNextWith(SyncFailure failure) => _queuedFailures.add(failure);

  /// Pushes a status to whoever is watching.
  void emit(SyncStatus status) => _statuses.add(status);

  /// The routing keys queued so far, oldest first.
  List<String> get types => [for (final command in queued) command.type];

  @override
  Future<Result<OutboxEntry, SyncFailure>> enqueue(
    SyncCommand command, {
    ConflictPolicy policy = const ConflictPolicy.lastWriteWins(),
  }) async {
    final failure = _takeFailure();
    if (failure != null) return Failed(failure);

    queued.add(command);
    policies.add(policy);

    _minted++;
    final entry =
        (OutboxEntryBuilder()
              ..withId('entry-$_minted')
              ..of(command)
              ..under(policy))
            .build();
    _entries.add(entry);
    return Success(entry);
  }

  @override
  Future<Result<SyncStatus, SyncFailure>> drain() async {
    final failure = _takeFailure();
    if (failure != null) return Failed(failure);

    // Draining a fake sends nothing anywhere. What it can honestly report is
    // how much is waiting, which is what a badge renders.
    return Success(
      _entries.isEmpty
          ? const SyncStatus.idle()
          : SyncStatus.draining(pending: _entries.length),
    );
  }

  @override
  Future<Result<List<OutboxEntry>, SyncFailure>> awaitingReview() async {
    final failure = _takeFailure();
    if (failure != null) return Failed(failure);

    return Success([
      for (final entry in _entries)
        if (entry.blockedReason != null) entry,
    ]);
  }

  @override
  Future<Result<OutboxEntry, SyncFailure>> retry(OutboxEntryId id) async {
    final failure = _takeFailure();
    if (failure != null) return Failed(failure);

    for (final entry in _entries) {
      if (entry.id == id) return Success(entry);
    }
    // The queue has no "no such entry" case, and does not need one: a
    // reference to an entry can only have come from this queue. Reporting it
    // as an unreadable store is the closest honest answer.
    return Failed(OutboxUnavailable(detail: 'no entry ${id.value}'));
  }

  @override
  Stream<SyncStatus> statusChanges() => _statuses.stream;

  /// Releases the status stream. Call from `addTearDown`.
  Future<void> dispose() => _statuses.close();

  SyncFailure? _takeFailure() =>
      _queuedFailures.isEmpty ? null : _queuedFailures.removeAt(0);
}
