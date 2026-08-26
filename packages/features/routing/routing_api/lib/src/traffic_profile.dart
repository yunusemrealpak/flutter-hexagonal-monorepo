import 'package:core_kernel/core_kernel.dart';
import 'package:meta/meta.dart';

import 'routing_failure.dart';

/// How fast a courier actually moves right now.
///
/// Deliberately coarse: one speed and one congestion multiplier for the whole
/// area, rather than a per-edge travel-time matrix. That is a *product*
/// calibration rather than a simplification for the sake of the example — the
/// two optimisers behind `RouteOptimizerPort` have to consume the same profile,
/// and a matrix is something only the remote solver could produce. A shape
/// only one implementation can fill is a shape the port cannot promise.
///
/// The consequence is worth stating plainly: ETAs from this feature are good
/// enough to order stops and to tell a courier roughly when they will be
/// somewhere. They are not good enough to promise a customer a fifteen-minute
/// slot, and nothing in this package pretends otherwise.
@immutable
final class TrafficProfile {
  const TrafficProfile._({
    required this.freeFlowKmh,
    required this.congestion,
  });

  /// What the product assumes when nothing is known.
  ///
  /// Thirty kilometres an hour with no congestion — an urban average that
  /// already includes stopping at lights. Named here rather than appearing as
  /// a literal in whichever optimiser was written first.
  static const TrafficProfile assumed = TrafficProfile._(
    freeFlowKmh: 30,
    congestion: 1,
  );

  /// Reads a profile, refusing one that would produce a route of infinite or
  /// negative length.
  static Result<TrafficProfile, RoutingFailure> of({
    required double freeFlowKmh,
    required double congestion,
  }) {
    if (freeFlowKmh <= 0 || freeFlowKmh.isNaN) {
      return Failed(
        MalformedRouteValue(
          field: 'freeFlowKmh',
          reason: '$freeFlowKmh is not a speed',
        ),
      );
    }
    if (congestion < 1 || congestion.isNaN || congestion.isInfinite) {
      return Failed(
        MalformedRouteValue(
          field: 'congestion',
          reason: '$congestion is not a multiplier of 1 or more',
        ),
      );
    }
    return Success(
      TrafficProfile._(freeFlowKmh: freeFlowKmh, congestion: congestion),
    );
  }

  /// The speed on an empty road, in kilometres per hour.
  final double freeFlowKmh;

  /// How much longer a journey takes than it would on an empty road.
  ///
  /// `1.0` is free flow, `2.0` is twice as long. It multiplies *time* rather
  /// than dividing speed, because that is the number a traffic service
  /// reports and the two are only the same until somebody adds a road closure.
  final double congestion;

  /// How long [metres] takes at this profile.
  Duration timeFor(double metres) {
    final metresPerSecond = freeFlowKmh * 1000 / 3600;
    final seconds = metres / metresPerSecond * congestion;
    return Duration(milliseconds: (seconds * 1000).round());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrafficProfile &&
          other.freeFlowKmh == freeFlowKmh &&
          other.congestion == congestion;

  @override
  int get hashCode => Object.hash(freeFlowKmh, congestion);

  @override
  String toString() => 'TrafficProfile(${freeFlowKmh}km/h x$congestion)';
}
