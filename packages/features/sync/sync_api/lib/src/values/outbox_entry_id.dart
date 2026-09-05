import 'package:core_kernel/core_kernel.dart';

import '../failures/sync_failure.dart';

/// Identifies one queued piece of work, for as long as it takes to land.
///
/// Generated from the `IdGenerator` port when the entry is queued, never from
/// a database sequence. An outbox is written on a device that may be offline
/// for a shift, so the identifier has to exist before anything has seen the
/// server — and it has to stay distinguishable from an identifier another
/// device produced at the same second.
///
/// It is also the idempotency handle for the transport: a command that was
/// delivered but whose acknowledgement was lost is retried under the same
/// identifier, and the server is expected to recognise it as the same work.
/// That is why the value survives a retry unchanged, and why nothing in this
/// package ever regenerates one.
final class OutboxEntryId extends ValueObject<String> {
  const OutboxEntryId._(super.value);

  /// Reads an entry identifier from [raw].
  static Result<OutboxEntryId, SyncFailure> parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const Failed(
        MalformedEntry(field: 'id', reason: 'is empty'),
      );
    }
    return Success(OutboxEntryId._(trimmed));
  }
}
