import 'package:core_kernel/core_kernel.dart';

import '../../failures/routing_failure.dart';
import '../../values/geo_point.dart';
import '../../values/traffic_profile.dart';

/// Reports how fast traffic is moving around a point.
///
/// A port of its own rather than something the optimiser fetches, and the
/// reason is scenario 4 again: `RemoteSolverOptimizer` could ask a traffic
/// service and `LocalHeuristicOptimizer` could not, and a port whose two
/// implementations see different inputs is a port whose contract cannot be
/// written down. So a use case asks this one, and hands the same answer to
/// whichever optimiser is bound.
///
/// It returns a `Result` because it reaches a network. What a caller does with
/// a failure is not to give up — `TrafficProfile.assumed` is what an
/// offline device plans with, and an assumed profile produces a usable
/// ordering even when the times attached to it are guesses.
abstract interface class TrafficDataPort {
  /// The conditions around [area], at [at].
  ///
  /// [at] is passed rather than read from a clock inside the adapter, because
  /// a dispatcher planning tomorrow morning's routes at five in the afternoon
  /// wants tomorrow morning's traffic. An adapter that used "now" would answer
  /// a different question from the one asked.
  Future<Result<TrafficProfile, RoutingFailure>> around(
    GeoPoint area, {
    required DateTime at,
  });
}
