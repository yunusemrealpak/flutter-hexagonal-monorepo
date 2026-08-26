import 'package:core_kernel/core_kernel.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'routing_failure.freezed.dart';

/// Everything that can go wrong on a routing port, or inside a route plan.
///
/// Sealed, so a caller that handles the cases exhaustively keeps compiling
/// only for as long as it still handles all of them.
@freezed
sealed class RoutingFailure extends Failure with _$RoutingFailure {
  const RoutingFailure._();

  /// A value object refused the input it was given.
  const factory RoutingFailure.malformedValue({
    required String field,
    required String reason,
  }) = MalformedRouteValue;

  /// A stop's address never resolved to a point on the map.
  ///
  /// The single most important failure in this package. An optimiser cannot
  /// order stops it cannot place, and the honest answer is to say which stop
  /// rather than to guess a position — a route planned around a guessed
  /// coordinate sends a courier to the wrong street with full confidence.
  const factory RoutingFailure.stopNotGeocoded({
    required String stopId,
    required String address,
  }) = StopNotGeocoded;

  /// The constraints cannot all be satisfied at once.
  ///
  /// A `maxStops` below the number of stops, two `mustStartAt` naming
  /// different stops, a `mustEndAt` naming a stop that is not in the list.
  /// Reporting it is the optimiser's job; deciding what to do about it is the
  /// caller's, which is why it is a failure rather than a silently relaxed
  /// constraint.
  const factory RoutingFailure.constraintUnsatisfiable({
    required String constraint,
    required String reason,
  }) = ConstraintUnsatisfiable;

  /// A sequence does not describe the stops it was given.
  ///
  /// A stop missing, a stop twice, a stop that is not on the plan. Any of the
  /// three would produce a route a courier cannot drive, and the resequence
  /// path is where a dispatcher's drag-and-drop reaches the domain.
  const factory RoutingFailure.sequenceDoesNotMatch({
    required String reason,
  }) = SequenceDoesNotMatch;

  /// Nothing is planned for this courier.
  const factory RoutingFailure.noPlan(String courier) = NoPlan;

  /// The device's position could not be read.
  const factory RoutingFailure.positionUnavailable({String? detail}) =
      PositionUnavailable;

  /// The optimiser, the traffic service or the cache could not be reached.
  const factory RoutingFailure.routingUnavailable({String? detail}) =
      RoutingUnavailable;
}
