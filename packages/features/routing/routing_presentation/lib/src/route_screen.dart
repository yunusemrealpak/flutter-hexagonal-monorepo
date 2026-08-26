import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:routing_api/routing_api.dart';

import 'route_controller.dart';
import 'route_view_state.dart';

/// The route, in the order it will be driven.
///
/// **The same widget in both apps, over two different optimisers.** A courier
/// in a tunnel is looking at a nearest-neighbour ordering their phone
/// computed; a dispatcher is looking at a solver's answer from a data centre.
/// Nothing here can tell the difference, because both arrive as a `RoutePlan`
/// through `RoutingFacade` — which is what scenario 4 is worth once you are
/// past the port itself.
///
/// Deliberately plain: no colours, no typography, no spacing scale. Those come
/// from `design_system`, which arrives in phase 7, and inventing them here
/// would mean deleting them then. What this screen demonstrates now is the
/// part that will not change — a widget renders a sealed state exhaustively
/// and reaches nothing but contracts.
final class RouteScreen extends StatefulWidget {
  /// Creates the screen over [controller].
  const RouteScreen({
    required this.controller,
    this.reorderable = false,
    super.key,
  });

  /// What drives it.
  final RouteController controller;

  /// Whether this viewer may change the driving order.
  ///
  /// A flag from the app rather than a `PermissionChecker` call here, and the
  /// reason is that the answer is not about routing. Reordering somebody's
  /// afternoon is a dispatcher capability that identity grants; the app knows
  /// which of its two shells it is, has already resolved the route's
  /// `requiredPermission` through `PermissionChecker` to let the viewer in at
  /// all, and is the only thing entitled to decide this. Defaults to false, so
  /// forgetting to think about it fails in the safe direction.
  final bool reorderable;

  @override
  State<RouteScreen> createState() => _RouteScreenState();

  /// Turns a failure into something a person can act on.
  ///
  /// Static and public so that a test can assert on the sentence without
  /// pumping a widget tree, and so that an app rendering the same failure in a
  /// different shape — a banner, a toast — does not reimplement the wording.
  ///
  /// Exhaustive over `RoutingFailure`, which is the point of it being sealed:
  /// the day routing learns a new way to fail, this stops compiling instead of
  /// quietly showing a courier the wrong sentence.
  static String describe(RoutingFailure failure) => switch (failure) {
    NoPlan() => 'No route has been planned for you yet.',
    SequenceDoesNotMatch() => 'That order does not describe this route.',
    ConstraintUnsatisfiable() => 'These stops cannot all be fitted in.',
    StopNotGeocoded(:final address) => 'One stop has no location: $address',
    PositionUnavailable() =>
      'No position yet. This is the route as it was planned.',
    RoutingUnavailable() =>
      'The planner could not be reached. This route is from this device.',
    MalformedRouteValue(:final field) => 'Something is wrong with $field.',
  };
}

class _RouteScreenState extends State<RouteScreen> {
  @override
  void initState() {
    super.initState();
    // initState cannot be async, and the load is genuinely fire-and-forget:
    // its result reaches the screen through the controller's notification
    // rather than through this call.
    widget.controller.watch();
    unawaited(widget.controller.load());
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) => switch (widget.controller.state) {
      RouteIdle() || RouteLoading() => const Center(
        child: Text('Working out your route'),
      ),
      RouteUnplanned() => const Center(
        // Not an error. This is where every day starts.
        child: Text('No route has been planned for you yet.'),
      ),
      // `StopSequence.empty` is explicitly not a failure — a courier who has
      // not been given work yet has an empty route — so it gets a sentence
      // rather than an error.
      RouteReady(:final plan) when plan.etas.isEmpty => const Center(
        child: Text('Nothing to drive today'),
      ),
      RouteReady(:final plan, :final visited, :final refusal) => _Stops(
        plan: plan,
        visited: visited,
        refusal: refusal,
        reorderable: widget.reorderable,
        onArrived: widget.controller.markArrived,
        onMoveUp: (stop) => unawaited(widget.controller.moveUp(stop)),
      ),
      RouteFailed(:final failure) => Center(
        child: Text(RouteScreen.describe(failure)),
      ),
    },
  );
}

final class _Stops extends StatelessWidget {
  const _Stops({
    required this.plan,
    required this.visited,
    required this.reorderable,
    required this.onArrived,
    required this.onMoveUp,
    this.refusal,
  });

  final RoutePlan plan;
  final Set<StopId> visited;
  final RoutingFailure? refusal;
  final bool reorderable;
  final void Function(StopId) onArrived;
  final void Function(StopId) onMoveUp;

  @override
  Widget build(BuildContext context) {
    // The estimates are already in visiting order, so the list is walked from
    // them rather than from the sequence: one source for the order and the
    // times means the two cannot disagree about which stop is third.
    final byId = {for (final stop in plan.stops) stop.id: stop};
    final next = plan.nextStopAfter(visited);
    final refused = refusal;

    return ListView(
      children: [
        if (refused != null) Text(RouteScreen.describe(refused)),
        Text('${plan.sequence.length} stops, back at ${hhmm(plan.finishesAt)}'),
        for (final (index, eta) in plan.etas.indexed)
          _StopTile(
            stop: byId[eta.stop]!,
            eta: eta,
            isNext: eta.stop == next,
            isDone: visited.contains(eta.stop),
            onArrived: () => onArrived(eta.stop),
            onMoveUp: reorderable && index > 0
                ? () => onMoveUp(eta.stop)
                : null,
          ),
      ],
    );
  }

  /// Formats an instant as `HH:mm`, in UTC.
  ///
  /// UTC and no locale, on purpose. Turning an instant into a courier's wall
  /// clock needs a timezone and a locale, both of which arrive with
  /// `design_system` and the app's localisation in phase 7; inventing a
  /// half-answer here would mean deleting it then. Every instant in a
  /// `RoutePlan` is already UTC, so this formats what it is given rather than
  /// converting it and hoping.
  static String hhmm(DateTime instant) {
    final at = instant.toUtc();
    return '${at.hour.toString().padLeft(2, '0')}:'
        '${at.minute.toString().padLeft(2, '0')}';
  }
}

final class _StopTile extends StatelessWidget {
  const _StopTile({
    required this.stop,
    required this.eta,
    required this.isNext,
    required this.isDone,
    required this.onArrived,
    this.onMoveUp,
  });

  final Stop stop;
  final Eta eta;
  final bool isNext;
  final bool isDone;
  final VoidCallback onArrived;
  final VoidCallback? onMoveUp;

  @override
  Widget build(BuildContext context) {
    final moveUp = onMoveUp;

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(stop.label),
          Text(_Stops.hhmm(eta.arrivesAt)),
          // Three separate marks rather than one status line. A stop can be
          // the next one *and* already forecast late, and a single line would
          // have to choose which of the two a courier is told.
          if (isNext) const Text('Next'),
          if (eta.isLate) const Text('Late'),
          if (isDone)
            const Text('Done')
          else
            GestureDetector(onTap: onArrived, child: const Text('Arrived')),
          if (moveUp != null)
            GestureDetector(onTap: moveUp, child: const Text('Move up')),
        ],
      ),
    );
  }
}
