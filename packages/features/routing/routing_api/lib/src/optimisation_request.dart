import 'package:freezed_annotation/freezed_annotation.dart';

import 'geo_point.dart';
import 'route_constraint.dart';
import 'stop.dart';
import 'traffic_profile.dart';

part 'optimisation_request.freezed.dart';

/// Everything an optimiser is given, and nothing it is not.
///
/// A type rather than five parameters, because there are two implementations
/// of `RouteOptimizerPort` and one contract kit that runs against both: a
/// request that can be built once and handed to either is what makes "the same
/// question, asked of two answers" expressible at all.
///
/// **Why the traffic profile is in the request rather than fetched by the
/// optimiser.** `RemoteSolverOptimizer` could ask a traffic service itself and
/// `LocalHeuristicOptimizer` could not, and a port whose two implementations
/// see different inputs is a port whose contract cannot be written down. So the
/// use case fetches it, through `TrafficDataPort`, and both optimisers get the
/// same number.
///
/// **Why time windows are not here.** They are on the stops, because a window
/// is a fact about a place. See `RouteConstraint`.
@freezed
abstract class OptimisationRequest with _$OptimisationRequest {
  /// Describes one optimisation.
  const factory OptimisationRequest({
    /// Where the courier is starting from.
    required GeoPoint origin,

    /// The stops to order. May be empty.
    required List<Stop> stops,

    /// When the courier leaves [origin], in UTC.
    required DateTime departAt,

    /// How fast they will be moving.
    @Default(TrafficProfile.assumed) TrafficProfile traffic,

    /// The rules the ordering has to respect.
    @Default(<RouteConstraint>[]) List<RouteConstraint> constraints,
  }) = _OptimisationRequest;
}
