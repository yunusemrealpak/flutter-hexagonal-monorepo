import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core_kernel/core_kernel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:identity_api/identity_api.dart';
import 'package:routing_api/routing_api.dart';

import 'route_event.dart';
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
/// [FollowedRouteBloc] for the vehicle on the route, [SupervisedRouteBloc] for
/// the desk overriding it. That replaced a `reorderable` boolean the app
/// passed to the screen: the flag said what this viewer may do, while the type
/// says what this app can *answer* — and only one of those is checked by the
/// compiler. A bloc keeps that split intact, because the reorder events reach
/// a handler only on the subclass that registers one.
///
/// **The subscription is a handler, not a field.** `RouteWatched` is
/// `restartable()` and holds the change stream through `emit.onEach`, which
/// replaced a nullable `StreamSubscription`, the `??=` that stopped a second
/// `watch()` opening a second one, and a `dispose` override. Watching twice
/// still yields one subscription; the second start cancels the first rather
/// than being ignored.
abstract base class RouteBloc extends Bloc<RouteEvent, RouteViewState> {
  /// Creates the bloc over the planning port, for one courier.
  ///
  /// [visited] seeds the stops already done, so that a screen reopened halfway
  /// through an afternoon does not send the courier back to the depot.
  RouteBloc({
    required this._planning,
    required this._courier,
    Set<StopId> visited = const {},
    // A copy: a caller that kept the set it seeded would otherwise be able to
    // change what the courier has visited from outside the bloc.
  }) : _visited = Set<StopId>.of(visited),
       super(const RouteIdle()) {
    on<RouteWatched>(_onWatched, transformer: restartable());
    on<RouteRequested>(_onRequested, transformer: droppable());
    on<StopArrived>(_onArrived);
  }

  final RoutePlanning _planning;
  final ActorId _courier;
  final Set<StopId> _visited;

  /// Whose route is on screen.
  @protected
  ActorId get courier => _courier;

  /// Reads the route the courier should be driving.
  ///
  /// **A query, and only a query.** This used to call
  /// `recalculateOnDeviation`, which reads the calling device's position and
  /// may replace the plan — so a dispatcher opening somebody else's route
  /// compared the desk's coordinates against that courier's next stop.
  /// [FollowedRouteBloc] overrides it to check for a deviation as well,
  /// because on a courier's phone that check is exactly what opening the
  /// screen means.
  @protected
  Future<Result<RoutePlan, RoutingFailure>> fetch() =>
      _planning.currentPlan(courier: _courier);

  /// Follows this courier's plan, so that a replan somewhere else redraws.
  ///
  /// The filter on [RoutePlan.courier] is not defensive tidiness. A dispatcher
  /// container has one routing graph and many couriers' routes moving through
  /// it, and a screen that redrew on every plan would show one courier the
  /// stops of whoever was replanned last.
  Future<void> _onWatched(RouteWatched event, Emitter<RouteViewState> emit) =>
      emit.onEach<RoutePlan>(
        _planning.changes(),
        onData: (plan) {
          if (plan.courier != _courier) return;
          emit(RouteReady(plan, visited: snapshot()));
        },
      );

  /// Reads the route, and drops a second read that arrives while one is out.
  ///
  /// `droppable()` rather than `restartable()`: on a courier's phone this is
  /// `recalculateOnDeviation`, which may *replace* the plan, and two of those
  /// in flight is two replans of one afternoon. A repeated tap on the retry
  /// button is the same request twice.
  Future<void> _onRequested(
    RouteRequested event,
    Emitter<RouteViewState> emit,
  ) async {
    emit(const RouteLoading());
    emit(settled(await fetch()));
  }

  /// Records that the courier has been to a stop.
  ///
  /// Local and synchronous: nothing about routing changes when a stop is done,
  /// only which stop is next. What *happened* at the stop — the signature, the
  /// photograph, the failed attempt — is `delivery`'s to record, and a routing
  /// screen that tried to would be the second place in the product that knows
  /// what a delivery is.
  void _onArrived(StopArrived event, Emitter<RouteViewState> emit) {
    if (!_visited.add(event.stop)) return;
    if (state case RouteReady(:final plan)) {
      emit(RouteReady(plan, visited: snapshot()));
    }
  }

  /// [plan] as the route, or the reason there is none.
  @protected
  RouteViewState settled(Result<RoutePlan, RoutingFailure> plan) =>
      switch (plan) {
        Success(value: final route) => RouteReady(route, visited: snapshot()),
        // Nothing planned is where a courier starts every day, not an error.
        Failed(failure: NoPlan()) => const RouteUnplanned(),
        Failed(:final failure) => RouteFailed(failure),
      };

  /// [failure] beside a route that is still on screen.
  ///
  /// With nothing to keep, the failure is all there is to show.
  @protected
  RouteViewState refused(RoutingFailure failure) => switch (state) {
    RouteReady(:final plan) => RouteReady(
      plan,
      visited: snapshot(),
      refusal: failure,
    ),
    _ => RouteFailed(failure),
  };

  /// An unmodifiable copy, so that a state a widget is rendering cannot change
  /// underneath it when the next arrival is recorded.
  @protected
  Set<StopId> snapshot() => Set<StopId>.unmodifiable(_visited);
}

/// The bloc for the vehicle that is on the route.
///
/// It holds `RouteFollowing` as well, and that interface is the one whose
/// ports read *this device's* position. An app that cannot honestly answer
/// that — a desk — cannot build this class, which is the whole point of the
/// type existing.
final class FollowedRouteBloc extends RouteBloc {
  /// Creates the bloc over both ports a courier's app can answer.
  FollowedRouteBloc({
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
  Future<Result<RoutePlan, RoutingFailure>> fetch() =>
      _following.recalculateOnDeviation(courier: courier, visited: snapshot());
}

/// The bloc for the desk that overrides a route it is not driving.
///
/// It holds `RouteSupervision`, and it deliberately does not hold
/// `RouteFollowing`: a dispatcher may reorder somebody's afternoon and cannot
/// say where that person is.
final class SupervisedRouteBloc extends RouteBloc {
  /// Creates the bloc over the two ports a desk can answer.
  SupervisedRouteBloc({
    required super.planning,
    required this._supervision,
    required super.courier,
    super.visited,
  }) {
    on<ReorderRequested>(_onReorder, transformer: sequential());
  }

  final RouteSupervision _supervision;

  /// Hands the domain a new driving order.
  ///
  /// **`sequential()`, and the order is computed inside the handler.** Two
  /// reorders are two different edits and both have to land, in the order they
  /// were made — but the second is only meaningful against the plan the first
  /// produced. Reading `plan.sequence.order` when the gesture happens, rather
  /// than when its turn comes, is what makes a dispatcher's second drag undo
  /// their first.
  ///
  /// It builds an order and hands it over; it does not decide whether the
  /// order is drivable, because that decision is `StopSequence`'s and making
  /// it twice is how the two copies drift apart.
  ///
  /// A refusal keeps the route on screen and reports itself beside it. The
  /// domain declined to change the plan, so the plan is still the truth —
  /// dropping to [RouteFailed] would blank a valid route because somebody
  /// dragged a row somewhere it could not go.
  Future<void> _onReorder(
    ReorderRequested event,
    Emitter<RouteViewState> emit,
  ) async {
    final order = switch (event) {
      RouteResequenced(:final order) => order,
      StopMovedUp(:final stop) => _movedUp(stop),
    };
    if (order == null) return;

    final resequenced = await _supervision.resequence(
      courier: courier,
      order: order,
    );

    emit(
      switch (resequenced) {
        Success(value: final plan) => settled(Success(plan)),
        Failed(:final failure) => refused(failure),
      },
    );
  }

  /// The order with [stop] one place earlier, or `null` when there is no such
  /// order — the stop is already first, or there is no route on screen.
  ///
  /// This is a dispatcher's drag-and-drop reduced to the one gesture a list
  /// can express without a layout system.
  List<StopId>? _movedUp(StopId stop) {
    if (state case RouteReady(:final plan)) {
      final order = [...plan.sequence.order];
      final index = order.indexOf(stop);
      if (index <= 0) return null;

      return order
        ..removeAt(index)
        ..insert(index - 1, stop);
    }
    return null;
  }
}
