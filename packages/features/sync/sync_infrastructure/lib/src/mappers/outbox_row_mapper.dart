import 'package:core_kernel/core_kernel.dart';
import 'package:storage_drift/storage_drift.dart' as db;
import 'package:sync_api/sync_api.dart';

/// Translates between a row of `outbox_entries` and the domain's `OutboxEntry`.
///
/// Two types with the same name, which is why `storage_drift` is imported with
/// a prefix. That collision is not an accident of naming: drift generates a
/// data class per table, and the whole point of a mapper is that the table's
/// shape and the domain's shape are allowed to differ. Aliasing the import
/// makes the two visible side by side instead of forcing one of them to be
/// renamed to accommodate the other.
///
/// Three translations happen here, and each one is a decision the domain must
/// not carry:
///
/// **`type` splits into `feature` and `operation`.** The table has two columns
/// because a person reading a stuck queue wants to filter by feature; the
/// domain has one routing key because that is what the composition root maps
/// to a handler. The split is on the first `.`, and a key with no dot files
/// under a feature of `unknown` rather than failing — a row that cannot be
/// stored is work that has been lost, and that is a worse outcome than a row
/// filed under the wrong heading.
///
/// **`ConflictPolicy` becomes a string, and back.** The union is closed here
/// and the column is open, so reading is where the two can disagree: a value
/// written by a newer release comes back as `lastWriteWins`, the option that
/// keeps the device's work, rather than as a failure that strands the row.
///
/// **Nothing about `RetrySchedule` is stored.** The schedule is a rule, and
/// rules ship with the app. What is stored is the *outcome* of applying it —
/// `nextAttemptAt` — so a device killed mid-backoff comes back with its waits
/// intact rather than retrying everything at once.
abstract final class OutboxRowMapper {
  /// The string written to the `conflict_policy` column for each case.
  static const String _lastWriteWins = 'lastWriteWins';
  static const String _serverWins = 'serverWins';
  static const String _manualReview = 'manualReview';

  /// The feature a routing key with no `.` in it is filed under.
  static const String unknownFeature = 'unknown';

  /// Turns a stored row into the entry the domain works with.
  static Result<OutboxEntry, SyncFailure> toDomain(db.OutboxEntry row) {
    final id = OutboxEntryId.parse(row.id);
    if (id case Failed(:final failure)) return Failed(failure);

    return id.map(
      (value) => OutboxEntry(
        id: value,
        type: _typeOf(row),
        payload: row.payload,
        policy: policyFrom(row.conflictPolicy),
        queuedAt: row.createdAt,
        attempts: row.attemptCount,
        lastAttemptAt: row.lastAttemptAt,
        nextAttemptAt: row.nextAttemptAt,
        blockedReason: row.blockedReason,
      ),
    );
  }

  /// Turns a domain entry into the row that stores it.
  static db.OutboxEntry toRow(OutboxEntry entry) {
    final separator = entry.type.indexOf('.');
    return db.OutboxEntry(
      id: entry.id.value,
      feature: separator <= 0
          ? unknownFeature
          : entry.type.substring(0, separator),
      operation: separator < 0
          ? entry.type
          : entry.type.substring(separator + 1),
      payload: entry.payload,
      createdAt: entry.queuedAt,
      attemptCount: entry.attempts,
      lastAttemptAt: entry.lastAttemptAt,
      conflictPolicy: policyName(entry.policy),
      nextAttemptAt: entry.nextAttemptAt,
      blockedReason: entry.blockedReason,
    );
  }

  /// The column value for [policy].
  static String policyName(ConflictPolicy policy) => switch (policy) {
    LastWriteWins() => _lastWriteWins,
    ServerWins() => _serverWins,
    ManualReview() => _manualReview,
  };

  /// The policy a stored string means.
  ///
  /// An unrecognised value — a downgrade, a hand-edited database, a column
  /// default from a release that had different names — reads as
  /// `lastWriteWins`. It is the only one of the three that neither discards
  /// the device's work nor demands a person's attention, so it is the safe
  /// direction for a value nobody can interpret.
  static ConflictPolicy policyFrom(String stored) => switch (stored) {
    _serverWins => const ConflictPolicy.serverWins(),
    _manualReview => const ConflictPolicy.manualReview(),
    _ => const ConflictPolicy.lastWriteWins(),
  };

  static String _typeOf(db.OutboxEntry row) => row.feature == unknownFeature
      ? row.operation
      : '${row.feature}.${row.operation}';
}
