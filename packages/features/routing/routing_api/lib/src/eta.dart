import 'package:freezed_annotation/freezed_annotation.dart';

import 'stop_id.dart';

part 'eta.freezed.dart';

/// When a courier is expected at a stop, and when they are expected to leave.
///
/// Generated with `freezed`, and it is the shape this workspace generates
/// happily: no identity of its own — two ETAs with the same contents *are* the
/// same estimate — nothing to validate, nothing secret.
///
/// The two instants are both here rather than one plus a service time,
/// because the difference between them is not always the service time. A
/// courier who arrives before a stop's window opens waits, and that wait
/// belongs in the estimate the next stop is computed from — otherwise every
/// ETA after the first early arrival is optimistic by the length of the wait.
///
/// [isLate] is carried rather than derived on read for the same reason
/// `nextAttemptAt` is stored in the outbox: the answer depends on the window
/// the stop had *when the route was planned*, and recomputing it against a
/// window somebody has since corrected would silently change history.
@freezed
abstract class Eta with _$Eta {
  /// Describes one stop's estimate.
  const factory Eta({
    /// Which stop.
    required StopId stop,

    /// When the courier is expected to arrive, in UTC.
    required DateTime arrivesAt,

    /// When they are expected to leave, in UTC.
    ///
    /// Arrival, plus any wait for the window to open, plus the service time.
    required DateTime departsAt,

    /// Whether this arrival misses the stop's window.
    ///
    /// A plan can legitimately contain a late stop: refusing to produce one
    /// would leave a courier with no route at all on a morning that started
    /// badly, which is worse than a route that says which stop is at risk.
    @Default(false) bool isLate,
  }) = _Eta;
}
