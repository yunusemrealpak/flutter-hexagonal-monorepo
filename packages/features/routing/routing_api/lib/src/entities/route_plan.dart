import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';

import '../failures/routing_failure.dart';
import '../values/eta.dart';
import '../values/geo_point.dart';
import '../values/route_plan_id.dart';
import '../values/stop_id.dart';
import '../values/stop_sequence.dart';
import '../values/traffic_profile.dart';
import 'stop.dart';

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
  /// The one thing it can refuse is a sequence that does not describe [stops]
  /// exactly. It used to be able to refuse an unplaceable stop as well, and no
  /// longer can: `Stop.place` is the only way to make one and it will not
  /// produce a stop without coordinates. An invalid state that cannot be
  /// constructed does not need a failure branch.
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

    return Success(
      RoutePlan._(
        id: id,
        courier: courier,
        origin: origin,
        stops: List<Stop>.unmodifiable(stops),
        sequence: sequence,
        etas: List<Eta>.unmodifiable(
          _estimate(
            origin: origin,
            order: sequence.order,
            byId: {for (final stop in stops) stop.id: stop},
            departAt: departAt.toUtc(),
            traffic: traffic,
          ),
        ),
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
    final to = _pointOf(nextStop);
    if (index < 0 || to == null) {
      return Failed(
        SequenceDoesNotMatch(reason: '${nextStop.value} is not on this route'),
      );
    }

    // The leg starts at the previous stop, not at the depot. Judging every leg
    // against the origin would report a deviation for a courier who is
    // correctly halfway across the route.
    final from = index == 0 ? origin : _pointOf(sequence.order[index - 1]);
    if (from == null) {
      return Failed(
        SequenceDoesNotMatch(
          reason: '${sequence.order[index - 1].value} is not on this route',
        ),
      );
    }

    return Success(
      position.distanceTo(to) > from.distanceTo(to) + toleranceMetres,
    );
  }

  GeoPoint? _pointOf(StopId id) {
    for (final stop in stops) {
      if (stop.id == id) return stop.at;
    }
    return null;
  }

  /// Walks the order once, accumulating arrival and departure instants.
  ///
  /// The wait for a window that has not opened yet is added to the *departure*
  /// as well as being visible in the arrival, so that the next leg starts from
  /// when the courier actually left. Without that, every estimate after the
  /// first early arrival is optimistic by the length of the wait.
  ///
  /// It returns a plain list rather than a `Result`, because there is nothing
  /// left here that can fail: every stop carries a `GeoPoint`, so the walk is
  /// arithmetic all the way down.
  static List<Eta> _estimate({
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
      final to = stop.at;
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

    return etas;
  }

  @override
  String toString() =>
      'RoutePlan(${id.value}, ${courier.value}, ${sequence.length} stops)';
}
