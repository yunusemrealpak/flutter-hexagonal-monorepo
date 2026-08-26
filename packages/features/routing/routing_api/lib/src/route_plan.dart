import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';

import 'eta.dart';
import 'geo_point.dart';
import 'route_plan_id.dart';
import 'routing_failure.dart';
import 'stop.dart';
import 'stop_id.dart';
import 'stop_sequence.dart';
import 'traffic_profile.dart';

/// One courier's route, in the order they will drive it and with the times
/// that follow from that order.
///
/// **The estimates are computed here, not by the optimiser.** That is the
/// single most important decision in this package, and it is what makes
/// scenario 4 work at all: `LocalHeuristicOptimizer` and
/// `RemoteSolverOptimizer` decide *order* and nothing else, so the only thing
/// the contract kit has to compare is a permutation. Had each optimiser
/// returned its own ETAs, the two would have drifted the first time one of
/// them rounded differently, and no suite could have told a better answer from
/// a wrong one.
///
/// It also puts the rule where the rule belongs. "Arrival plus any wait for
/// the window plus the service time" is a fact about how this operation works,
/// not about how a solver works, and a remote solver written by another team
/// would otherwise be free to disagree with it.
///
/// An `Entity`: equality is by [id], because a plan whose sequence a
/// dispatcher rearranged is still the same plan. Plans are replaced rather
/// than edited across a shift, so that the one a courier was following at
/// eleven o'clock is still something that can be pointed at.
final class RoutePlan extends Entity<RoutePlanId> {
  const RoutePlan._({
    required super.id,
    required this.courier,
    required this.origin,
    required this.stops,
    required this.sequence,
    required this.etas,
    required this.departAt,
    required this.traffic,
  });

  /// Builds a plan from an ordering, computing the estimates.
  ///
  /// Fails when [sequence] does not describe [stops] exactly, and when a stop
  /// on the route has no coordinates — both are routes a courier cannot drive,
  /// and both are better reported than approximated.
  static Result<RoutePlan, RoutingFailure> of({
    required RoutePlanId id,
    required ActorId courier,
    required GeoPoint origin,
    required List<Stop> stops,
    required StopSequence sequence,
    required DateTime departAt,
    TrafficProfile traffic = TrafficProfile.assumed,
  }) {
    final checked = StopSequence.over(stops, sequence.order);
    if (checked case Failed(:final failure)) return Failed(failure);

    final byId = {for (final stop in stops) stop.id: stop};
    final estimates = _estimate(
      origin: origin,
      order: sequence.order,
      byId: byId,
      departAt: departAt.toUtc(),
      traffic: traffic,
    );
    if (estimates case Failed(:final failure)) return Failed(failure);

    return estimates.map(
      (etas) => RoutePlan._(
        id: id,
        courier: courier,
        origin: origin,
        stops: List<Stop>.unmodifiable(stops),
        sequence: sequence,
        etas: List<Eta>.unmodifiable(etas),
        departAt: departAt.toUtc(),
        traffic: traffic,
      ),
    );
  }

  /// Whose route this is.
  final ActorId courier;

  /// Where the courier starts.
  final GeoPoint origin;

  /// Every stop on the route, in no particular order.
  final List<Stop> stops;

  /// The order they are visited in.
  final StopSequence sequence;

  /// When the courier is expected at each stop, in visiting order.
  final List<Eta> etas;

  /// When the courier leaves [origin], in UTC.
  final DateTime departAt;

  /// The conditions the estimates were computed under.
  final TrafficProfile traffic;

  /// The estimate for [stop], or `null` when it is not on this route.
  Eta? etaFor(StopId stop) {
    for (final eta in etas) {
      if (eta.stop == stop) return eta;
    }
    return null;
  }

  /// When the courier is expected to finish, or [departAt] on an empty route.
  DateTime get finishesAt => etas.isEmpty ? departAt : etas.last.departsAt;

  /// The stops this plan already expects to miss their window.
  ///
  /// A plan is allowed to contain them. Refusing to produce one would leave a
  /// courier with no route at all on a morning that started badly, which is
  /// worse than a route that says which stop is at risk.
  List<StopId> get lateStops => [
    for (final eta in etas.where((eta) => eta.isLate)) eta.stop,
  ];

  /// The next stop after everything in [visited], or `null` when the route is
  /// finished.
  StopId? nextStopAfter(Set<StopId> visited) {
    for (final id in sequence.order) {
      if (!visited.contains(id)) return id;
    }
    return null;
  }

  /// Rebuilds this plan in a different order, recomputing the estimates.
  ///
  /// This is where a dispatcher's drag-and-drop reaches the domain, and where
  /// a sequence that drops a stop, repeats one or names a stranger is refused.
  Result<RoutePlan, RoutingFailure> resequenced(List<StopId> order) {
    final sequence = StopSequence.over(stops, order);
    if (sequence case Failed(:final failure)) return Failed(failure);

    return sequence.flatMap(
      (value) => RoutePlan.of(
        id: id,
        courier: courier,
        origin: origin,
        stops: stops,
        sequence: value,
        departAt: departAt,
        traffic: traffic,
      ),
    );
  }

  /// Whether a courier at [position] has left the route on the way to
  /// [nextStop].
  ///
  /// The test is *"am I further from the next stop than the leg to it was
  /// long, plus a tolerance?"* — which catches a wrong turn and a wrong
  /// district while accepting the ordinary case of driving around a block. It
  /// is a heuristic, not a map-matching algorithm, and it is here rather than
  /// in an adapter because both optimisers' plans have to be judged deviated
  /// by the same rule.
  ///
  /// [toleranceMetres] is what absorbs the difference between a straight line
  /// and a road. A city grid roughly doubles a great-circle distance, so a
  /// tolerance smaller than the leg itself will report a deviation on every
  /// normal journey.
  Result<bool, RoutingFailure> hasDeviated({
    required GeoPoint position,
    required StopId nextStop,
    required double toleranceMetres,
  }) {
    final index = sequence.positionOf(nextStop);
    if (index < 0) {
      return Failed(
        SequenceDoesNotMatch(reason: '${nextStop.value} is not on this route'),
      );
    }

    final target = _placed(nextStop);
    if (target case Failed(:final failure)) return Failed(failure);

    final legStart = index == 0
        ? Success<GeoPoint, RoutingFailure>(origin)
        : _placed(sequence.order[index - 1]);
    if (legStart case Failed(:final failure)) return Failed(failure);

    return target.flatMap(
      (to) => legStart.map(
        (from) =>
            position.distanceTo(to) > from.distanceTo(to) + toleranceMetres,
      ),
    );
  }

  Result<GeoPoint, RoutingFailure> _placed(StopId id) {
    for (final stop in stops) {
      if (stop.id == id) return stop.placed;
    }
    return Failed(
      SequenceDoesNotMatch(reason: '${id.value} is not on this route'),
    );
  }

  /// Walks the order once, accumulating arrival and departure instants.
  ///
  /// The wait for a window that has not opened yet is added to the *departure*
  /// as well as being visible in the arrival, so that the next leg starts from
  /// when the courier actually left. Without that, every estimate after the
  /// first early arrival is optimistic by the length of the wait.
  static Result<List<Eta>, RoutingFailure> _estimate({
    required GeoPoint origin,
    required List<StopId> order,
    required Map<StopId, Stop> byId,
    required DateTime departAt,
    required TrafficProfile traffic,
  }) {
    final etas = <Eta>[];
    var from = origin;
    var clock = departAt;

    for (final id in order) {
      final stop = byId[id]!;
      final placed = stop.placed;
      if (placed case Failed(:final failure)) return Failed(failure);

      final to = placed.fold((point) => point, (_) => origin);
      final arrivesAt = clock.add(traffic.timeFor(from.distanceTo(to)));
      final wait = stop.window?.waitFrom(arrivesAt) ?? Duration.zero;
      final departsAt = arrivesAt.add(wait).add(stop.serviceTime.value);

      etas.add(
        Eta(
          stop: id,
          arrivesAt: arrivesAt,
          departsAt: departsAt,
          isLate: stop.isLateAt(arrivesAt),
        ),
      );

      from = to;
      clock = departsAt;
    }

    return Success(etas);
  }

  @override
  String toString() =>
      'RoutePlan(${id.value}, ${courier.value}, ${sequence.length} stops)';
}
