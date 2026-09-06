import 'package:routing_api/routing_api.dart';

/// What can happen to the route screen.
sealed class RouteEvent {
  const RouteEvent();
}

/// Follow this courier's plan, so that a replan somewhere else redraws.
final class RouteWatched extends RouteEvent {
  /// Creates the event.
  const RouteWatched();
}

/// Read the route the courier should be driving.
final class RouteRequested extends RouteEvent {
  /// Creates the event.
  const RouteRequested();
}

/// The courier has been to a stop.
final class StopArrived extends RouteEvent {
  /// Creates the event.
  const StopArrived(this.stop);

  /// Which stop.
  final StopId stop;
}

/// A change to the driving order.
///
/// **Sealed, and answered by one `on<ReorderRequested>` under
/// `sequential()`.** The two subclasses are the same operation described at
/// two distances — one names an order, the other names a gesture that has to
/// be turned into one — and computing that order is only correct against the
/// plan the *previous* edit produced. Under two registrations, or under
/// `concurrent()`, a dispatcher moving two rows in quick succession would have
/// the second gesture read the order the first one replaced, and would undo
/// it.
///
/// Only `SupervisedRouteBloc` registers a handler. A courier's bloc holds no
/// `RouteSupervision`, so on that bloc these events reach nothing — which is
/// the same guarantee the two classes have always given, one layer further in.
sealed class ReorderRequested extends RouteEvent {
  const ReorderRequested();
}

/// Move a stop one place earlier.
final class StopMovedUp extends ReorderRequested {
  /// Creates the event.
  const StopMovedUp(this.stop);

  /// Which stop moves.
  final StopId stop;
}

/// Replace the driving order outright.
final class RouteResequenced extends ReorderRequested {
  /// Creates the event.
  const RouteResequenced(this.order);

  /// The order the domain is asked to accept.
  final List<StopId> order;
}
