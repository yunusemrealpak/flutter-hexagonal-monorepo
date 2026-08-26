import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:flutter/foundation.dart';
import 'package:identity_api/identity_api.dart';
import 'package:routing_api/routing_api.dart';

import 'route_view_state.dart';

/// Drives the route screen.
///
/// It holds one port — `RoutingFacade` — and no implementations. **Which
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
/// A `ChangeNotifier` rather than a bloc, and that is a deliberate
/// non-decision: no state management library is a dependency of this workspace
/// yet, and introducing one here would make every feature inherit the choice.
/// The state type beside this class is the part that matters — swapping in a
/// bloc changes this file and nothing else, because a widget renders
/// `RouteViewState` and does not know what produced it.
final class RouteController extends ChangeNotifier {
  /// Creates the controller over the facade, for one courier.
  ///
  /// [visited] seeds the stops already done, so that a screen reopened halfway
  /// through an afternoon does not send the courier back to the depot.
  RouteController({
    required this._routing,
    required this._courier,
    Set<StopId> visited = const {},
    // A copy: a caller that kept the set it seeded would otherwise be able to
    // change what the courier has visited from outside the controller.
  }) : _visited = Set<StopId>.of(visited);

  final RoutingFacade _routing;
  final ActorId _courier;
  final Set<StopId> _visited;

  StreamSubscription<RoutePlan>? _plans;

  RouteViewState _state = const RouteIdle();

  /// What the screen should be showing.
  RouteViewState get state => _state;

  /// Follows this courier's plan, so that a replan somewhere else redraws.
  ///
  /// The filter on [RoutePlan.courier] is not defensive tidiness. A dispatcher
  /// container has one `RoutingFacade` and many couriers' routes moving
  /// through it, and a screen that redrew on every plan would show one courier
  /// the stops of whoever was replanned last.
  void watch() {
    _plans ??= _routing.changes().listen((plan) {
      if (plan.courier != _courier) return;
      _emit(RouteReady(plan, visited: _snapshot()));
    });
  }

  /// Reads the route the courier should be driving.
  ///
  /// `recalculateOnDeviation` rather than a read, because routing has no
  /// read-only "what is planned" method and should not grow one for this. That
  /// port already answers the question a screen is opening to ask — *what
  /// should I be driving now* — and it returns the plan whether or not it had
  /// to make a new one, so a caller never has to ask twice to find out what to
  /// draw.
  Future<void> load() async {
    _emit(const RouteLoading());

    final plan = await _routing.recalculateOnDeviation(
      courier: _courier,
      visited: _snapshot(),
    );

    _emit(
      switch (plan) {
        Success(value: final route) => RouteReady(
          route,
          visited: _snapshot(),
        ),
        // Nothing planned is where a courier starts every day, not an error.
        Failed(failure: NoPlan()) => const RouteUnplanned(),
        Failed(:final failure) => RouteFailed(failure),
      },
    );
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
      _emit(RouteReady(plan, visited: _snapshot()));
    } else {
      notifyListeners();
    }
  }

  /// Moves [stop] one place earlier and asks the domain to accept the result.
  ///
  /// This is a dispatcher's drag-and-drop reduced to the one gesture a list can
  /// express without a layout system. It builds an order and hands it over; it
  /// does not decide whether the order is drivable, because that decision is
  /// `StopSequence`'s and making it twice is how the two copies drift apart.
  Future<void> moveUp(StopId stop) async {
    if (_state case RouteReady(:final plan)) {
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
  /// dragged a row somewhere it could not go. With nothing on screen to keep,
  /// the failure is all there is to show.
  Future<void> reorder(List<StopId> order) async {
    final resequenced = await _routing.resequence(
      courier: _courier,
      order: order,
    );

    switch (resequenced) {
      case Success(value: final plan):
        _emit(RouteReady(plan, visited: _snapshot()));
      case Failed(:final failure):
        _emit(
          switch (_state) {
            RouteReady(:final plan) => RouteReady(
              plan,
              visited: _snapshot(),
              refusal: failure,
            ),
            _ => RouteFailed(failure),
          },
        );
    }
  }

  @override
  void dispose() {
    unawaited(_plans?.cancel());
    super.dispose();
  }

  /// An unmodifiable copy, so that a state a widget is rendering cannot change
  /// underneath it when the next arrival is recorded.
  Set<StopId> _snapshot() => Set<StopId>.unmodifiable(_visited);

  void _emit(RouteViewState next) {
    _state = next;
    notifyListeners();
  }
}
