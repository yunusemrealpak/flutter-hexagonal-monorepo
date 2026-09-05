import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';
import 'package:routing_api/routing_api.dart';

/// What a caller wants reordered.
typedef ResequenceRequest = ({ActorId courier, List<StopId> order});

/// What a caller wants the next stop for.
typedef ProgressRequest = ({ActorId courier, Set<StopId> visited});

/// Reorders a courier's plan by hand.
///
/// This is a dispatcher's drag-and-drop reaching the domain, and everything
/// that decides whether the new order is legal lives in `RoutePlan` — the use
/// case reads, applies and writes, and holds no rule of its own. A sequence
/// that drops a stop, repeats one or names a stranger is refused there, which
/// is why an optimiser and a human are held to the same standard.
final class Resequence
    implements UseCase<ResequenceRequest, Result<RoutePlan, RoutingFailure>> {
  /// Creates the use case.
  const Resequence({required this._cache});

  final RouteCache _cache;

  @override
  Future<Result<RoutePlan, RoutingFailure>> call(
    ResequenceRequest request,
  ) async {
    final RoutePlan plan;
    switch (await _cache.read(request.courier.value)) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        plan = value;
    }

    final RoutePlan moved;
    switch (plan.resequenced(request.order)) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        moved = value;
    }

    // Written before it is returned, and the failure *is* reported here —
    // unlike in PlanRoute. A dispatcher who reorders a route and is told it
    // worked has to be able to rely on the courier seeing that order; a plan
    // that was returned and not stored would show the new order on one screen
    // and the old one on the other.
    final written = await _cache.write(moved);
    if (written case Failed(:final failure)) return Failed(failure);

    return Success(moved);
  }
}

/// Answers what a courier should be heading for.
///
/// A read, and a thin one: `RoutePlan.nextStopAfter` walks the sequence and
/// returns the first stop the request has not marked visited. The reason
/// it is a use case at all is the cache read in front of it — a screen asking
/// "where next" must not have to know where plans are kept.
///
/// A finished route is `Success(null)`, not a failure. An empty afternoon is
/// something a courier earns.
final class NextStop
    implements UseCase<ProgressRequest, Result<StopId?, RoutingFailure>> {
  /// Creates the use case.
  const NextStop({required this._cache});

  final RouteCache _cache;

  @override
  Future<Result<StopId?, RoutingFailure>> call(
    ProgressRequest request,
  ) async {
    final plan = await _cache.read(request.courier.value);
    return plan.map((value) => value.nextStopAfter(request.visited));
  }
}

/// Answers what a courier is on now, and changes nothing by asking.
///
/// **The use case that was missing, and whose absence caused a bug.** Before
/// phase 8 routing had no read-only "what is planned", so the route screen
/// opened by calling `recalculateOnDeviation` — a command that reads this
/// device's position and may replace the plan. On a courier's phone that is
/// merely generous. On a dispatcher's desk, opening somebody else's route
/// compared *the desk's* coordinates against *their* next stop.
///
/// Command-query separation is the rule that was being broken, and it is worth
/// stating as the reason rather than as a citation: asking a question must not
/// change the answer.
final class CurrentPlan
    implements UseCase<ActorId, Result<RoutePlan, RoutingFailure>> {
  /// Creates the use case.
  const CurrentPlan({required this._cache});

  final RouteCache _cache;

  @override
  Future<Result<RoutePlan, RoutingFailure>> call(ActorId courier) =>
      _cache.read(courier.value);
}
