import 'package:core_kernel/core_kernel.dart';

import 'outbox_entry.dart';
import 'outbox_entry_id.dart';
import 'sync_cursor.dart';
import 'sync_failure.dart';

/// Where queued work is kept while it waits.
///
/// A driven port, and the one that has to be durable: everything else in this
/// feature can be rebuilt after a crash, and this cannot. An implementation
/// that kept entries in memory would lose a shift's deliveries when the
/// operating system reclaimed the app, which is the exact scenario the outbox
/// exists for. `app_courier` binds the drift-backed adapter for that reason and
/// `app_dispatcher` binds the in-memory one, because a dispatcher is at a desk
/// with a connection.
///
/// The port speaks in entries and cursors, never in rows or SQL. That is what
/// lets `sync_application` — which may not depend on `platform/*` — orchestrate
/// a queue whose storage it cannot name.
abstract interface class OutboxStore {
  /// Writes [entry], replacing whatever was stored under its identifier.
  ///
  /// An upsert rather than an insert. A feature that crashed between
  /// generating an identifier and writing the row retries with the same
  /// identifier, and the queue must end up with one entry rather than two —
  /// duplicate work here is a duplicate payment at the door.
  Future<Result<void, SyncFailure>> put(OutboxEntry entry);

  /// Reads one entry.
  Future<Result<OutboxEntry, SyncFailure>> byId(OutboxEntryId id);

  /// The entries that are not blocked, oldest first.
  ///
  /// Ordering is part of the contract, not an implementation detail: work
  /// queued earlier describes a world the later work assumes. Draining a
  /// payment before the delivery it belongs to would present the server with a
  /// collection against a shipment it has not been told about.
  ///
  /// [limit] bounds one drain so that a device coming back from a long day
  /// offline does not hold a single database transaction open across five
  /// hundred requests. The default is stated here rather than left to each
  /// implementation: a caller that omits it is calling through this interface,
  /// so the value it gets has to come from the contract.
  Future<Result<List<OutboxEntry>, SyncFailure>> pending({int limit = 50});

  /// The entries that are blocked, oldest first.
  Future<Result<List<OutboxEntry>, SyncFailure>> blocked();

  /// Removes [id] once the server has accepted the work, or once its policy
  /// says the device's version loses.
  ///
  /// Removing an identifier that is not there succeeds. A drain that crashed
  /// after the server accepted and before the row was dropped retries the
  /// removal, and the second attempt is not an error.
  Future<Result<void, SyncFailure>> drop(OutboxEntryId id);

  /// Where this device believes the server is.
  ///
  /// [SyncCursor.beginning] on a device that has never synchronised, rather
  /// than a failure: having no position is a state, not a fault.
  Future<Result<SyncCursor, SyncFailure>> cursor();

  /// Records the position the server last reported.
  Future<Result<void, SyncFailure>> saveCursor(SyncCursor cursor);

  /// Counts one failed delivery of [id] and schedules the next try.
  ///
  /// Separate from [put], and the separation is the point. [put] writes a
  /// whole entry from a value the caller is holding — one read at the top of a
  /// drain, several requests ago. This changes the three fields a failed
  /// attempt changes and leaves the payload, the policy and the blocked reason
  /// as the store has them.
  ///
  /// **The count is the store's, not the caller's.** An implementation must
  /// increment what it holds rather than write a number worked out from a copy
  /// somebody else read, because that number is what the retry schedule is
  /// spent against and two drains that both wrote "attempt 4" would give a
  /// device twice the budget it is allowed.
  ///
  /// Recording against an identifier that is not there succeeds, for the
  /// reason [drop] gives: a drain racing a person who resolved the entry must
  /// not stop on work that is no longer queued.
  Future<Result<void, SyncFailure>> recordAttempt(
    OutboxEntryId id, {
    required DateTime at,
    required DateTime nextAttemptAt,
  });

  /// Records that the server took [id]'s work and is now at [cursor].
  ///
  /// **One method because it is one fact.** A caller that dropped the row and
  /// then saved the cursor would, if it died in between, come back having
  /// forgotten work the server has and believing the server is somewhere it is
  /// not — so its next envelope goes out from a position it has already been
  /// told is stale.
  ///
  /// Expressing that as an intent rather than as a transaction is what keeps
  /// storage out of this contract. `OutboxStore.transaction(...)` would make
  /// every implementation offer a notion only one of them has, and would let a
  /// caller in `sync_application` — which may not name a database — write one
  /// anyway.
  ///
  /// Accepting an identifier that is not there succeeds and still moves the
  /// cursor. A drain that crashed after this call and retried it finds no row
  /// and has still been told where the server is.
  Future<Result<void, SyncFailure>> accepted(
    OutboxEntryId id,
    SyncCursor cursor,
  );
}
