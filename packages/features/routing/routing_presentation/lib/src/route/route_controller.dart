import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:flutter/foundation.dart';
import 'package:identity_api/identity_api.dart';
import 'package:routing_api/routing_api.dart';

import 'route_view_state.dart';

/// Drives the route screen, in the part both audiences share.
///
/// It holds one port — `RoutePlanning` — and no implementations. **Which
/// optimiser produced the order on screen is not something this class can find
/// out**, and that is scenario 4 arriving at the layer it was for: the same
/// widget renders a nearest-neighbour ordering computed on a phone in a tunnel
/// and a solver's answer computed in a data centre, because both reach it as a
/// `RoutePlan` through the same contract. `app_courier` and `app_dispatcher`
/// share every line of this file.
///
/// **Whose route it is arrives through the constructor.** Routing has one
/// presentation package and two apps use it for different subjects — a courier
/// sees their own afternoon, a dispatcher opens somebody else's — so reading
/// the actor from `SessionReader`, the way `shipments_presentation_courier`
/// does, would be right in one app and wrong in the other. The app decides,
/// and passes an `ActorId`.
///
/// **What an app may do to the route is decided by which subclass it builds.**
/// `FollowedRouteController` for the vehicle on the route,
/// `SupervisedRouteController` for the desk overriding it. That replaced a
/// `reorderable` boolean the app passed to the screen: the flag said what this
/// viewer may do, while the type says what this app can *answer* — and only
/// one of those is checked by the compiler.
///
/// A `ChangeNotifier` rather than a bloc, and that is a deliberate
/// non-decision: no state management library is a dependency of this workspace
/// yet, and introducing one here would make every feature inherit the choice.
/// The state type beside this class is the part that matters — swapping in a
/// bloc changes this file and nothing else, because a widget renders
/// `RouteViewState` and does not know what produced it.
abstract base class RouteController extends ChangeNotifier {
  /// Creates the controller over the planning port, for one courier.
  ///
  /// [visited] seeds the stops already done, so that a screen reopened halfway
  /// through an afternoon does not send the courier back to the depot.
  RouteController({
    required this._planning,
    required this._courier,
    Set<StopId> visited = const {},
    // A copy: a caller that kept the set it seeded would otherwise be able to
    // change what the courier has visited from outside the controller.
  }) : _visited = Set<StopId>.of(visited);

  final RoutePlanning _planning;
  final ActorId _courier;
  final Set<StopId> _visited;

  StreamSubscription<RoutePlan>? _plans;

  RouteViewState _state = const RouteIdle();

  /// What the screen should be showing.
  RouteViewState get state => _state;

  /// Whose route is on screen.
  @protected
  ActorId get courier => _courier;

  /// Follows this courier's plan, so that a replan somewhere else redraws.
  ///
  /// The filter on [RoutePlan.courier] is not defensive tidiness. A dispatcher
  /// container has one routing graph and many couriers' routes moving through
  /// it, and a screen that redrew on every plan would show one courier the
  /// stops of whoever was replanned last.
  void watch() {
    _plans ??= _planning.changes().listen((plan) {
      if (plan.courier != _courier) return;
      _emit(RouteReady(plan, visited: snapshot()));
    });
  }

  /// Reads the route the courier should be driving.
  ///
  /// **A query, and only a query.** This used to call
  /// `recalculateOnDeviation`, which reads the calling device's position and
  /// may replace the plan — so a dispatcher opening somebody else's route
  /// compared the desk's coordinates against that courier's next stop.
  /// [FollowedRouteController] overrides it to check for a deviation as well,
  /// because on a courier's phone that check is exactly what opening the
  /// screen means.
  Future<void> load() async {
    beginLoading();
    report(await _planning.currentPlan(courier: _courier));
  }

  /// Records that the courier has been to [stop].
  ///
  /// Local and synchronous: nothing about routing changes when a stop is done,
  /// only which stop is next. What *happened* at the stop — the signature, the
  /// photograph, the failed attempt — is `delivery`'s to record, and a routing
  /// screen that tried to would be the second place in the product that knows
  /// what a delivery is.
  void markArrived(StopId stop) {
    if (!_visited.add(stop)) return;
    if (_state case RouteReady(:final plan)) {
      _emit(RouteReady(plan, visited: snapshot()));
    } else {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    unawaited(_plans?.cancel());
    super.dispose();
  }

  /// Puts the screen into its loading state.
  @protected
  void beginLoading() => _emit(const RouteLoading());

  /// Shows [plan] as the route, or the reason there is none.
  @protected
  void report(Result<RoutePlan, RoutingFailure> plan) => _emit(
    switch (plan) {
      Success(value: final route) => RouteReady(route, visited: snapshot()),
      // Nothing planned is where a courier starts every day, not an error.
      Failed(failure: NoPlan()) => const RouteUnplanned(),
      Failed(:final failure) => RouteFailed(failure),
    },
  );

  /// Reports [failure] beside a route that is still on screen.
  ///
  /// With nothing to keep, the failure is all there is to show.
  @protected
  void refuse(RoutingFailure failure) => _emit(
    switch (_state) {
      RouteReady(:final plan) => RouteReady(
        plan,
        visited: snapshot(),
        refusal: failure,
      ),
      _ => RouteFailed(failure),
    },
  );

  /// An unmodifiable copy, so that a state a widget is rendering cannot change
  /// underneath it when the next arrival is recorded.
  @protected
  Set<StopId> snapshot() => Set<StopId>.unmodifiable(_visited);

  void _emit(RouteViewState next) {
    _state = next;
    notifyListeners();
  }
}

/// The controller for the vehicle that is on the route.
///
/// It holds `RouteFollowing` as well, and that interface is the one whose
/// ports read *this device's* position. An app that cannot honestly answer
/// that — a desk — cannot build this class, which is the whole point of the
/// type existing.
final class FollowedRouteController extends RouteController {
  /// Creates the controller over both ports a courier's app can answer.
  FollowedRouteController({
    required super.planning,
    required this._following,
    required super.courier,
    super.visited,
  });

  final RouteFollowing _following;

  /// Reads the route, checking for a deviation on the way.
  ///
  /// A courier opening this screen is asking *what should I be driving now*,
  /// and the honest answer to that includes noticing they have left the route.
  /// It returns the plan whether or not it had to make a new one, so the
  /// screen never has to ask twice.
  @override
  Future<void> load() async {
    beginLoading();
    report(
      await _following.recalculateOnDeviation(
        courier: courier,
        visited: snapshot(),
      ),
    );
  }
}

/// The controller for the desk that overrides a route it is not driving.
///
/// It holds `RouteSupervision`, and it deliberately does not hold
/// `RouteFollowing`: a dispatcher may reorder somebody's afternoon and cannot
/// say where that person is.
final class SupervisedRouteController extends RouteController {
  /// Creates the controller over the two ports a desk can answer.
  SupervisedRouteController({
    required super.planning,
    required this._supervision,
    required super.courier,
    super.visited,
  });

  final RouteSupervision _supervision;

  /// Moves [stop] one place earlier and asks the domain to accept the result.
  ///
  /// This is a dispatcher's drag-and-drop reduced to the one gesture a list
  /// can express without a layout system. It builds an order and hands it
  /// over; it does not decide whether the order is drivable, because that
  /// decision is `StopSequence`'s and making it twice is how the two copies
  /// drift apart.
  Future<void> moveUp(StopId stop) async {
    if (state case RouteReady(:final plan)) {
      final order = [...plan.sequence.order];
      final index = order.indexOf(stop);
      if (index <= 0) return;

      order
        ..removeAt(index)
        ..insert(index - 1, stop);
      await reorder(order);
    }
  }

  /// Replaces the driving order with [order].
  ///
  /// A refusal keeps the route on screen and reports itself beside it. The
  /// domain declined to change the plan, so the plan is still the truth —
  /// dropping to [RouteFailed] would blank a valid route because somebody
  /// dragged a row somewhere it could not go.
  Future<void> reorder(List<StopId> order) async {
    final resequenced = await _supervision.resequence(
      courier: courier,
      order: order,
    );

    switch (resequenced) {
      case Success(value: final plan):
        report(Success(plan));
      case Failed(:final failure):
        refuse(failure);
    }
  }
}
