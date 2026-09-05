import 'package:freezed_annotation/freezed_annotation.dart';

part 'geo_fence_verdict.freezed.dart';

/// How far the courier is from where the parcel is going.
///
/// **A fact, not a decision.** The port reports the distance and whether it is
/// inside the radius it was configured with; whether an attempt may start
/// anyway is `StartAttempt`'s call. That split is what lets a dispatcher app
/// bind an adapter that always answers "inside" — recording a hand-over the
/// office was told about by telephone — without the rule about couriers
/// changing anywhere.
///
/// [allowedMetres] is carried rather than assumed, because it is a setting: a
/// dense city and a rural round want different numbers, and a use case that
/// hard-coded one would be wrong in whichever operation it was not written
/// for.
@freezed
abstract class GeoFenceVerdict with _$GeoFenceVerdict {
  /// Describes where the courier is standing.
  const factory GeoFenceVerdict({
    /// Whether [metresAway] is within [allowedMetres].
    required bool isInside,

    /// How far from the address, in metres.
    required double metresAway,

    /// How far the operation is prepared to accept.
    required double allowedMetres,
  }) = _GeoFenceVerdict;
}
