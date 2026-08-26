import 'package:core_kernel/core_kernel.dart';

import 'optimisation_request.dart';
import 'routing_failure.dart';
import 'stop_sequence.dart';

/// Decides what order to visit stops in.
///
/// **This is the port scenario 4 is about.** Two implementations ship:
///
/// - `LocalHeuristicOptimizer` — nearest neighbour with a 2-opt improvement
///   pass, running on the device, working offline. `app_courier` binds it,
///   because a courier in a dead zone still has to be given an order to drive.
/// - `RemoteSolverOptimizer` — posts the request to a server that runs a real
///   vehicle-routing solver. `app_dispatcher` binds it, because an operator
///   planning forty routes at eight in the morning has a connection and needs
///   answers a phone cannot compute.
///
/// Both pass `runRouteOptimizerContract` in `routing_testing`. Not one line of
/// `routing_application` changes between the two apps, and no test in this
/// feature knows which one it is running against.
///
/// **What it returns is a permutation, and only a permutation.** The estimates
/// are computed by `RoutePlan`, from the order plus the traffic profile plus
/// the service times. That split is what makes the contract writable: the kit
/// compares orderings, which are exactly comparable, instead of instants, which
/// two implementations would round differently on the first Tuesday.
///
/// It is also what keeps a business rule out of a solver. "Arrival plus any
/// wait for the window plus the service time" is how this operation works, and
/// a remote solver written by another team would otherwise be free to disagree.
abstract interface class RouteOptimizerPort {
  /// Orders the stops in [request].
  ///
  /// The returned sequence names every stop in the request exactly once — that
  /// is the first thing the contract kit checks, because an optimiser that
  /// drops a stop drops a parcel.
  ///
  /// Returns `ConstraintUnsatisfiable` rather than relaxing a constraint. An
  /// optimiser that quietly truncated a route to fit `maxStops` would be
  /// deciding which four parcels are not delivered today, and that is not a
  /// decision this layer is entitled to make.
  Future<Result<StopSequence, RoutingFailure>> optimise(
    OptimisationRequest request,
  );
}
