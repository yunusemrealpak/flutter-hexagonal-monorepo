/// The sync contract: a queue that carries every feature's writes and knows
/// none of them.
///
/// This package is scenario 3 of the architecture, and it is the only feature
/// in the workspace whose pubspec names no other feature. The arrow runs
/// against the intuition: `delivery`, `payments` and `incidents` depend on
/// `sync_api` so that they can describe a durable write, and `sync` depends on
/// nothing of theirs — because the only thing it ever sees is a routing key
/// and an opaque payload.
///
/// **The contract features implement.** `SyncCommand` — two strings, `type`
/// and `payload`. A feature's `_application` package declares one per write it
/// wants carried, and the composition root maps the type to a transport
/// handler. Nothing in this library can decode a payload, and nothing in it
/// should ever be able to.
///
/// **The domain.** `OutboxEntry` is the durable record of one piece of work;
/// `RetrySchedule` decides how long to wait after a failure and when to stop;
/// `ConflictPolicy` decides what a stale write means, and is chosen by the
/// feature that queued it because that is a business question. `SyncEnvelope`
/// is one attempt, `SyncCursor` the server position an attempt is made
/// against, `SyncStatus` what a screen shows.
///
/// **The driving port.** `SyncFacade`, implemented by `sync_application`.
///
/// **The driven ports.** `OutboxStore`, `CommandTransportPort`,
/// `ClockSkewPort`, answered by `sync_infrastructure`.
library;

export 'src/entities/outbox_entry.dart';
export 'src/failures/sync_failure.dart';
export 'src/ports/driven/clock_skew_port.dart';
export 'src/ports/driven/command_transport_port.dart';
export 'src/ports/driven/outbox_store.dart';
export 'src/ports/driving/sync_facade.dart';
export 'src/values/conflict_policy.dart';
export 'src/values/outbox_entry_id.dart';
export 'src/values/retry_schedule.dart';
export 'src/values/sync_command.dart';
export 'src/values/sync_cursor.dart';
export 'src/values/sync_envelope.dart';
export 'src/values/sync_status.dart';
