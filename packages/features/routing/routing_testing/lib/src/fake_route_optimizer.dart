import 'package:core_kernel/core_kernel.dart';
import 'package:routing_api/routing_api.dart';

/// A `RouteOptimizerPort` that keeps the order it was given.
///
/// The third implementation of the port, bound by `app_harness`, and it is a
/// *fake* rather than a stub: it really validates the constraints, really
/// refuses a stop it cannot place, and really honours the anchors — which is
/// why it passes `runRouteOptimizerContract` alongside the two real ones.
///
/// What it does not do is optimise. That is deliberate and it is the whole
/// value of having it: a test that runs against this optimiser is testing the
/// *use case*, and the order it gets back is the order it put in, so an
/// assertion about a route reads as an assertion about routing rather than
/// about a heuristic. A test that needed the heuristic runs against the
/// heuristic.
///
/// It also demonstrates the floor of the contract. Every rule the kit checks
/// is satisfied here in about twenty lines, which is the evidence that those
/// rules are about correctness rather than about quality.
final class FakeRouteOptimizer implements RouteOptimizerPort {
  final List<OptimisationRequest> _requests = [];
  final List<RoutingFailure> _queuedFailures = [];

  List<StopId>? _scripted;

  /// Every request that arrived, oldest first.
  List<OptimisationRequest> get requests => List.unmodifiable(_requests);

  /// Makes the next call return [failure].
  ///
  /// Failure is part of a port's contract, so the fake standing in for it has
  /// to be able to produce one — otherwise the branch a use case takes when
  /// the solver is unreachable stays untested.
  void failNextWith(RoutingFailure failure) => _queuedFailures.add(failure);

  /// Makes the next call return exactly this order.
  ///
  /// For the tests that need a *specific* route rather than a valid one — a
  /// use case that has to notice a plan whose last stop is late, say.
  // ignore: use_setters_to_change_properties
  void answersWith(List<StopId> order) => _scripted = order;

  @override
  Future<Result<StopSequence, RoutingFailure>> optimise(
    OptimisationRequest request,
  ) async {
    _requests.add(request);

    final failure = _takeFailure();
    if (failure != null) return Failed(failure);

    final constraints = request.constraints;
    final checked = constraints.checkAgainst(request.stops);
    if (checked case Failed(:final failure)) return Failed(failure);

    // There is no "can this stop be placed?" check here any more, and none in
    // the two real optimisers either. `Stop.place` refuses a stop without
    // coordinates, so by the time a request reaches an optimiser every stop
    // on it has a GeoPoint. An unconstructible state needs no guard.
    final scripted = _scripted;
    _scripted = null;

    final order = constraints.anchored(
      scripted ?? [for (final stop in request.stops) stop.id],
    );
    return StopSequence.over(request.stops, order);
  }

  RoutingFailure? _takeFailure() =>
      _queuedFailures.isEmpty ? null : _queuedFailures.removeAt(0);
}
