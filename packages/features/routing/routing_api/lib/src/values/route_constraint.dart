import 'package:core_kernel/core_kernel.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../entities/stop.dart';
import '../failures/routing_failure.dart';
import 'stop_id.dart';

part 'route_constraint.freezed.dart';

/// A rule an optimiser has to respect while ordering stops.
///
/// A closed union rather than a bag of nullable fields on the request, so that
/// "no constraint" and "a constraint whose value happens to be null" cannot be
/// the same thing — and so that adding a fifth kind is a case rather than
/// another nullable field every implementation has to remember to read.
///
/// **What is deliberately not here: time windows.** A window is a fact about
/// the *place*, so it lives on `Stop` and every optimiser sees it whether or
/// not anybody asked for it. A window that travelled as a constraint could be
/// omitted by the caller and silently ignored by the implementation, which is
/// the failure mode where a pharmacy closes at six and the route arrives at
/// half past.
@freezed
sealed class RouteConstraint with _$RouteConstraint {
  const RouteConstraint._();

  /// The route has to begin at this stop.
  ///
  /// A depot, usually. Two of these naming different stops is a request no
  /// optimiser can satisfy, and reporting that is better than picking one.
  const factory RouteConstraint.mustStartAt(StopId stop) = MustStartAt;

  /// The route has to finish at this stop.
  const factory RouteConstraint.mustEndAt(StopId stop) = MustEndAt;

  /// The route may not contain more than this many stops.
  ///
  /// A vehicle's capacity, or a shift's length expressed the crude way. A
  /// request with more stops than this is unsatisfiable rather than truncated:
  /// silently dropping the last four parcels is a decision an optimiser is not
  /// entitled to make.
  const factory RouteConstraint.maxStops(int count) = MaxStops;

  /// The route's driving and service time may not exceed this.
  const factory RouteConstraint.maxDuration(Duration limit) = MaxDuration;

  /// A short, stable name for this constraint.
  ///
  /// Used in failure messages so that "unsatisfiable" says which one. Not for
  /// display: a screen localises, and a localisation key is not something a
  /// contract package should own.
  String get label => switch (this) {
    MustStartAt() => 'mustStartAt',
    MustEndAt() => 'mustEndAt',
    MaxStops() => 'maxStops',
    MaxDuration() => 'maxDuration',
  };
}

/// The rules every optimiser has to obey, written once.
///
/// An extension rather than three copies, and that is the point: without it,
/// `LocalHeuristicOptimizer`, `RemoteSolverOptimizer` and `FakeRouteOptimizer`
/// would each decide for themselves what two conflicting `mustStartAt`
/// constraints mean, and the contract kit could only assert the intersection
/// of whatever they happened to agree on.
///
/// It lives in `_api` because it is a *rule*, not an implementation — the same
/// reason `Shipment` holds its own transition table. Nothing here implements a
/// port declared in this package, so rule S8 is untouched.
extension RouteConstraints on List<RouteConstraint> {
  /// The stop the route has to begin at, if one was named.
  StopId? get requiredStart {
    for (final constraint in this) {
      if (constraint is MustStartAt) return constraint.stop;
    }
    return null;
  }

  /// The stop the route has to end at, if one was named.
  StopId? get requiredEnd {
    for (final constraint in this) {
      if (constraint is MustEndAt) return constraint.stop;
    }
    return null;
  }

  /// The most stops the route may contain, if a limit was set.
  int? get stopLimit {
    for (final constraint in this) {
      if (constraint is MaxStops) return constraint.count;
    }
    return null;
  }

  /// The longest the route may take, if a limit was set.
  ///
  /// Checked by the use case rather than by an optimiser, because it can only
  /// be evaluated once a `RoutePlan` exists — the duration follows from the
  /// order, and the order is what an optimiser is being asked for.
  Duration? get durationLimit {
    for (final constraint in this) {
      if (constraint is MaxDuration) return constraint.limit;
    }
    return null;
  }

  /// Refuses a set of constraints that cannot all hold over [stops].
  ///
  /// Every case here is a request no ordering satisfies, so reporting it is
  /// strictly better than producing a route that quietly breaks one of them.
  Result<void, RoutingFailure> checkAgainst(List<Stop> stops) {
    final ids = stops.map((stop) => stop.id).toSet();

    final starts = whereType<MustStartAt>().map((c) => c.stop).toSet();
    if (starts.length > 1) {
      return const Failed(
        ConstraintUnsatisfiable(
          constraint: 'mustStartAt',
          reason: 'two different stops are named as the start',
        ),
      );
    }
    final ends = whereType<MustEndAt>().map((c) => c.stop).toSet();
    if (ends.length > 1) {
      return const Failed(
        ConstraintUnsatisfiable(
          constraint: 'mustEndAt',
          reason: 'two different stops are named as the end',
        ),
      );
    }

    final start = requiredStart;
    if (start != null && !ids.contains(start)) {
      return Failed(
        ConstraintUnsatisfiable(
          constraint: 'mustStartAt',
          reason: '${start.value} is not one of the stops',
        ),
      );
    }
    final end = requiredEnd;
    if (end != null && !ids.contains(end)) {
      return Failed(
        ConstraintUnsatisfiable(
          constraint: 'mustEndAt',
          reason: '${end.value} is not one of the stops',
        ),
      );
    }
    if (start != null && start == end && stops.length > 1) {
      // One stop cannot be both ends of a route that has other stops on it.
      // A round trip back to a depot is two stops in the domain, not one
      // visited twice, and modelling it the other way would make "how many
      // parcels are on this route" ambiguous.
      return Failed(
        ConstraintUnsatisfiable(
          constraint: 'mustStartAt',
          reason: '${start.value} cannot be both the start and the end',
        ),
      );
    }

    final limit = stopLimit;
    if (limit != null && stops.length > limit) {
      return Failed(
        ConstraintUnsatisfiable(
          constraint: 'maxStops',
          reason: '${stops.length} stops exceeds a limit of $limit',
        ),
      );
    }

    return const Success(null);
  }

  /// Moves the required first and last stops into place in [order].
  ///
  /// Applied *after* an optimiser has chosen an ordering, so that a heuristic
  /// works on the whole set and the anchors are honoured regardless of what it
  /// decided. Doing it the other way — pinning first and optimising the rest —
  /// is also defensible, and it is a choice each implementation would then
  /// make differently, which is exactly what this extension exists to prevent.
  List<StopId> anchored(List<StopId> order) {
    final start = requiredStart;
    final end = requiredEnd;
    if (start == null && end == null) return order;

    final moved = List<StopId>.of(order);
    if (start != null && moved.remove(start)) moved.insert(0, start);
    if (end != null && moved.remove(end)) moved.add(end);
    return moved;
  }
}
