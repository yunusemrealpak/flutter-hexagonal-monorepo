import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:identity_api/identity_api.dart';

import 'shipment_status.dart';

part 'status_transition.freezed.dart';

/// One move the shipment actually made, kept so that the sequence can be
/// audited afterwards.
///
/// Generated: a transition is a record of what happened, it has no identity
/// of its own, there is nothing to validate — the state machine already
/// refused the moves that were not allowed — and nothing here is secret. That
/// is the whole test this workspace applies before reaching for `freezed`.
@freezed
abstract class StatusTransition with _$StatusTransition {
  /// Records a move from [from] to [to].
  const factory StatusTransition({
    /// The state the shipment left.
    required ShipmentStatus from,

    /// The state it entered.
    required ShipmentStatus to,

    /// When the move happened, in UTC, as reported by the `Clock` port.
    required DateTime at,

    /// Who caused it, where a person did.
    ///
    /// `null` for moves the system makes on its own — a sweep that returns
    /// undelivered parcels to the depot at the end of a shift has no actor,
    /// and inventing one would make the audit trail lie.
    ActorId? by,
  }) = _StatusTransition;

  const StatusTransition._();
}
