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
}
