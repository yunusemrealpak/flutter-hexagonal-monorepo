import 'package:core_kernel/core_kernel.dart';

import '../../failures/sync_failure.dart';
import '../../values/sync_cursor.dart';
import '../../values/sync_envelope.dart';

/// Carries one envelope to the server and reports where the server now is.
///
/// The narrowest port in the feature, and deliberately so. It takes an opaque
/// payload and a routing key, and it has no idea what either means — which is
/// what lets a single implementation carry every feature's writes, and what
/// stops `sync` accumulating a `switch` over feature names as the product
/// grows.
///
/// **Where the composition root comes in.** The registry that maps a
/// [SyncEnvelope.type] to the endpoint that answers it is built in an app, not
/// here. `sync_application` hands this port an envelope and reads back a
/// cursor; whether `delivery.completeAttempt` is a `POST /attempts` or a queue
/// message is a wiring decision the queue is not entitled to know.
///
/// The returned [SyncCursor] is the server's position *after* accepting the
/// work. Storing it is what makes the next envelope's conflict check
/// meaningful: a device that never advanced its cursor would report a conflict
/// against its own previous write.
abstract interface class CommandTransportPort {
  /// Delivers [envelope], returning the server's new position.
  ///
  /// Never throws. A rejected command comes back as `SyncFailure.rejected`, a
  /// stale cursor as `SyncFailure.conflict`, and everything that could be the
  /// network as `SyncFailure.offline` or `SyncFailure.transportFailed` —
  /// which is the distinction the retry schedule is built on.
  Future<Result<SyncCursor, SyncFailure>> send(SyncEnvelope envelope);
}
