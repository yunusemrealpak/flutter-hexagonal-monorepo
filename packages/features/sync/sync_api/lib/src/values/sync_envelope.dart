import 'package:freezed_annotation/freezed_annotation.dart';

import 'conflict_policy.dart';
import 'outbox_entry_id.dart';
import 'sync_cursor.dart';

part 'sync_envelope.freezed.dart';

/// One attempt at delivering one queued command, as the transport sees it.
///
/// Generated with `freezed`, and it is the shape this workspace generates
/// happily: no identity, nothing to validate, nothing to refuse. Two envelopes
/// with the same contents *are* the same attempt, so structural equality is
/// correct — which is precisely the opposite of `OutboxEntry` beside it, and
/// the reason that one is hand-written.
///
/// It is not a DTO. There is no `fromJson` here and there must not be: a DTO
/// belongs to `sync_infrastructure`, where the wire format lives, and the
/// mapper between the two is what stops a change in the API reaching this
/// package. What an envelope is instead is the *domain's* description of an
/// attempt — the command, plus the two facts the transport needs that the
/// entry does not carry.
@freezed
abstract class SyncEnvelope with _$SyncEnvelope {
  /// Creates the envelope.
  const factory SyncEnvelope({
    /// The entry this attempt belongs to, and the handle the server
    /// de-duplicates on.
    required OutboxEntryId id,

    /// The routing key the feature declared.
    required String type,

    /// The command body, still opaque.
    required String payload,

    /// What the feature wants done if the server has moved on.
    required ConflictPolicy policy,

    /// When the work happened, in the server's frame of reference.
    required DateTime queuedAt,

    /// Which attempt this is, counting from 1.
    ///
    /// Sent so that the server can tell a retry from a fresh write in its own
    /// logs. Nothing about the request changes because of it — a retry that
    /// behaved differently from the first attempt would defeat the idempotency
    /// the identifier buys.
    required int attempt,

    /// Where this device believes the server is.
    required SyncCursor cursor,
  }) = _SyncEnvelope;
}
