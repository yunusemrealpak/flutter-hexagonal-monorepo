import 'package:sync_api/sync_api.dart';

import 'outbox_row_mapper.dart';
import 'sync_envelope_dto.dart';

/// Translates between the domain's `SyncEnvelope` and the wire's DTO.
///
/// Hand-written, like every mapper in this workspace. A generated mapper would
/// have to be told what to do about a missing field, a policy name it does not
/// recognise and a timestamp in the wrong zone — which is the entire content
/// of this file, so the generator would only be moving the decisions into a
/// configuration nobody reads.
///
/// `toUtc()` on the way out is the one line that is easy to leave out and hard
/// to notice missing: a device set to Istanbul time would otherwise send local
/// instants that the server reads as UTC, and every offline write would appear
/// to have happened three hours early.
abstract final class SyncEnvelopeMapper {
  /// Turns an envelope into the body that is sent.
  static SyncEnvelopeDto toDto(SyncEnvelope envelope) => SyncEnvelopeDto(
    id: envelope.id.value,
    type: envelope.type,
    payload: envelope.payload,
    policy: OutboxRowMapper.policyName(envelope.policy),
    queuedAt: envelope.queuedAt.toUtc().toIso8601String(),
    attempt: envelope.attempt,
    cursor: envelope.cursor.value,
  );
}
