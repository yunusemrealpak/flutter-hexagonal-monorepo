import 'package:core_kernel/core_kernel.dart';
import 'package:routing_api/routing_api.dart';

/// Orders stops on the device: nearest neighbour, then a 2-opt improvement
/// pass.
///
/// **This is one half of scenario 4.** `app_courier` binds it, because a
/// courier who walks into a car park still has to be handed an order to drive,
/// and a phone cannot reach a solver from there. `app_dispatcher` binds
/// `RemoteSolverOptimizer` instead. Both satisfy `RouteOptimizerPort`, both
/// pass `runRouteOptimizerContract`, and `routing_application` cannot tell
/// them apart.
///
/// **Why these two algorithms.** Nearest neighbour is fast and produces a
/// route that is typically 20–25% longer than optimal; 2-opt takes that and
/// removes the crossings, which is where most of the difference lives. Neither
/// is state of the art and neither claims to be — the point of the port is
/// that the operation can buy a better answer without changing a use case, and
/// the point of this class is that it is a *usable* answer with no network.
///
/// **Determinism is a contract requirement, not an accident.** Ties are broken
/// on the stop identifier, and the 2-opt pass stops at a fixed iteration
/// count. An optimiser that reordered a route every time a screen refreshed
/// would move a courier's next stop while they were reading it.
///
/// It is pure computation — no clock, no randomness, no I/O — which is why it
/// is the only adapter in this workspace whose tests need nothing stood up.
final class LocalHeuristicOptimizer implements RouteOptimizerPort {
  /// Creates the optimiser.
  const LocalHeuristicOptimizer({this.improvementPasses = 8});

  /// How many times the 2-opt pass may sweep the route.
  ///
  /// Bounded rather than "until no improvement", because 2-opt on a
  /// pathological input converges slowly and this runs on a phone while a
  /// courier waits. Eight sweeps takes a twenty-stop route well past the point
  /// where further passes stop changing anything.
  final int improvementPasses;

  @override
  Future<Result<StopSequence, RoutingFailure>> optimise(
    OptimisationRequest request,
  ) async {
    final constraints = request.constraints;

    final checked = constraints.checkAgainst(request.stops);
    if (checked case Failed(:final failure)) return Failed(failure);

    // No "can this stop be placed?" guard, and none needed: `Stop.place` is
    // the only way to make a stop and it refuses one without coordinates, so
    // every stop that reaches an optimiser already carries a GeoPoint.
    final placed = {for (final stop in request.stops) stop.id: stop.at};
    if (placed.isEmpty) return const Success(StopSequence.empty);

    final nearest = _nearestNeighbour(request.origin, placed);
    final improved = _twoOpt(request.origin, nearest, placed);

    return StopSequence.over(
      request.stops,
      constraints.anchored(improved),
    );
  }

  /// Walks to the closest unvisited stop each time.
  ///
  /// Ties broken on the identifier, so two stops at the same distance always
  /// come out in the same order.
  List<StopId> _nearestNeighbour(
    GeoPoint origin,
    Map<StopId, GeoPoint> placed,
  ) {
    final remaining = placed.keys.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final order = <StopId>[];
    var from = origin;

    while (remaining.isNotEmpty) {
      var bestIndex = 0;
      var bestDistance = from.distanceTo(placed[remaining[0]]!);
      for (var i = 1; i < remaining.length; i++) {
        final distance = from.distanceTo(placed[remaining[i]]!);
        if (distance < bestDistance) {
          bestIndex = i;
          bestDistance = distance;
        }
      }
      final chosen = remaining.removeAt(bestIndex);
      order.add(chosen);
      from = placed[chosen]!;
    }

    return order;
  }

  /// Reverses segments while doing so shortens the route.
  ///
  /// This is what removes the crossings nearest neighbour leaves behind — the
  /// long hop back across the district that happens when the greedy walk
  /// strands one stop at the far end.
  List<StopId> _twoOpt(
    GeoPoint origin,
    List<StopId> order,
    Map<StopId, GeoPoint> placed,
  ) {
    if (order.length < 3) return order;

    final best = List<StopId>.of(order);
    var bestLength = _lengthOf(origin, best, placed);

    for (var pass = 0; pass < improvementPasses; pass++) {
      var improvedThisPass = false;

      for (var i = 0; i < best.length - 1; i++) {
        for (var j = i + 1; j < best.length; j++) {
          final candidate = List<StopId>.of(best)
            ..setRange(i, j + 1, best.sublist(i, j + 1).reversed);
          final length = _lengthOf(origin, candidate, placed);
          // Strictly shorter, so a reversal that changes nothing is not
          // applied. Accepting equal-length swaps would make the result depend
          // on iteration order rather than on the route.
          if (length < bestLength - 0.000001) {
            best
              ..clear()
              ..addAll(candidate);
            bestLength = length;
            improvedThisPass = true;
          }
        }
      }

      if (!improvedThisPass) break;
    }

    return best;
  }

  /// The total distance of visiting [order] starting from [origin].
  ///
  /// No return leg to the origin. A courier finishes where the last parcel is
  /// and goes home from there, and adding a phantom return would make the
  /// optimiser prefer routes that end near the depot for a journey nobody
  /// makes on the clock.
  double _lengthOf(
    GeoPoint origin,
    List<StopId> order,
    Map<StopId, GeoPoint> placed,
  ) {
    var total = 0.0;
    var from = origin;
    for (final id in order) {
      final to = placed[id]!;
      total += from.distanceTo(to);
      from = to;
    }
    return total;
  }
}
