import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:routing_api/routing_api.dart';

import 'route_controller.dart';
import 'route_view_state.dart';
import 'routing_strings.dart';

/// The route, in the order it will be driven.
///
/// **The same widget in both apps, over two different optimisers.** A courier
/// in a tunnel is looking at a nearest-neighbour ordering their phone
/// computed; a dispatcher is looking at a solver's answer from a data centre.
/// Nothing here can tell the difference, because both arrive as a `RoutePlan`
/// through `RoutingFacade` — which is what scenario 4 is worth once you are
/// past the port itself.
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

  /// Which string a failure should be shown as.
  ///
  /// Static and public so that a test can assert on the key without pumping a
  /// widget tree, and so that an app rendering the same failure in a different
  /// shape — a banner, a toast — does not reimplement the mapping.
  ///
  /// Exhaustive over `RoutingFailure`, which is the point of it being sealed:
  /// the day routing learns a new way to fail, this stops compiling instead of
  /// quietly showing a courier the wrong sentence.
  @visibleForTesting
  static String describe(RoutingFailure failure) => switch (failure) {
    NoPlan() => RoutingStrings.failureNoPlan,
    SequenceDoesNotMatch() => RoutingStrings.failureSequenceMismatch,
    ConstraintUnsatisfiable() => RoutingStrings.failureUnsatisfiable,
    StopNotGeocoded() => RoutingStrings.failureNotGeocoded,
    PositionUnavailable() => RoutingStrings.failurePositionUnavailable,
    RoutingUnavailable() => RoutingStrings.failurePlannerUnavailable,
    MalformedRouteValue() => RoutingStrings.failureMalformed,
  };

  /// The arguments [failure] contributes to its own message.
  @visibleForTesting
  static Map<String, Object?> argumentsFor(RoutingFailure failure) =>
      switch (failure) {
        StopNotGeocoded(:final address) => {'address': address},
        MalformedRouteValue(:final field) => {'field': field},
        NoPlan() ||
        SequenceDoesNotMatch() ||
        ConstraintUnsatisfiable() ||
        PositionUnavailable() ||
        RoutingUnavailable() => const {},
      };

  /// Whether [failure] leaves the courier looking at something usable.
  ///
  /// Two of the seven do. `PositionUnavailable` and `RoutingUnavailable` both
  /// mean "this is the route, just not a fresh one" — and a courier who is
  /// shown an error page for those has been stopped from driving a route that
  /// is perfectly drivable. They are drawn as a warning above the stops
  /// instead, which is what `RouteReady.refusal` carries.
  @visibleForTesting
  static bool isAdvisory(RoutingFailure failure) => switch (failure) {
    PositionUnavailable() || RoutingUnavailable() => true,
    NoPlan() ||
    SequenceDoesNotMatch() ||
    ConstraintUnsatisfiable() ||
    StopNotGeocoded() ||
    MalformedRouteValue() => false,
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
  Widget build(BuildContext context) {
    final strings = PeykStrings.of(context);

    return PeykScreen(
      title: strings.resolve(RoutingStrings.title),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) => switch (widget.controller.state) {
          RouteIdle() || RouteLoading() => const PeykLoadingView(),
          // Not an error. This is where every day starts, and its own key
          // rather than NoPlan's: a courier who has not been given work has
          // not hit a failure.
          RouteUnplanned() => PeykEmptyView(
            message: strings.resolve(RoutingStrings.unplanned),
          ),
          // `StopSequence.empty` is explicitly not a failure either — a route
          // planned with nothing in it is a quiet day.
          RouteReady(:final plan) when plan.etas.isEmpty => PeykEmptyView(
            message: strings.resolve(RoutingStrings.nothingToDrive),
          ),
          RouteReady(:final plan, :final visited, :final refusal) => _Stops(
            plan: plan,
            visited: visited,
            refusal: refusal,
            reorderable: widget.reorderable,
            onArrived: widget.controller.markArrived,
            onMoveUp: (stop) => unawaited(widget.controller.moveUp(stop)),
          ),
          RouteFailed(:final failure) => PeykFailureView(
            message: strings.resolve(
              RouteScreen.describe(failure),
              arguments: RouteScreen.argumentsFor(failure),
            ),
            onRetry: () => unawaited(widget.controller.load()),
          ),
        },
      ),
    );
  }
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
    final strings = PeykStrings.of(context);

    return ListView(
      children: [
        // An advisory rather than a failure view: the route below is drivable,
        // it is just not fresh. Replacing the stops with an error page would
        // stop a courier driving a route that works.
        if (refused != null)
          PeykChip(
            label: strings.resolve(
              RouteScreen.describe(refused),
              arguments: RouteScreen.argumentsFor(refused),
            ),
            intent: PeykIntent.warning,
          ),
        PeykText.body(
          strings.resolve(
            RoutingStrings.summary,
            arguments: {
              'stops': plan.sequence.length,
              'finishesAt': plan.finishesAt.toUtc(),
            },
          ),
        ),
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
    final strings = PeykStrings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PeykListRow(
          title: stop.label,
          subtitle: strings.resolve(
            RoutingStrings.arrivesAt,
            // A UTC instant, not "14:05". Turning it into a courier's wall
            // clock needs a timezone and a locale, and the app has both.
            arguments: {'arrivesAt': eta.arrivesAt.toUtc()},
          ),
          // Three separate marks rather than one status line. A stop can be
          // the next one *and* already forecast late, and a single line would
          // have to choose which of the two a courier is told.
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isNext)
                PeykChip(
                  label: strings.resolve(RoutingStrings.next),
                  intent: PeykIntent.info,
                ),
              if (eta.isLate) ...[
                if (isNext) const PeykGap.horizontal(PeykGapSize.tight),
                PeykChip(
                  label: strings.resolve(RoutingStrings.late),
                  intent: PeykIntent.warning,
                ),
              ],
            ],
          ),
        ),
        Row(
          children: [
            if (isDone)
              PeykChip(
                label: strings.resolve(RoutingStrings.done),
                intent: PeykIntent.success,
              )
            else
              PeykButton(
                label: strings.resolve(RoutingStrings.arrived),
                onPressed: onArrived,
                tone: PeykButtonTone.primary,
              ),
            if (moveUp != null) ...[
              const PeykGap.horizontal(PeykGapSize.betweenLines),
              PeykButton(
                label: strings.resolve(RoutingStrings.moveUp),
                onPressed: moveUp,
              ),
            ],
          ],
        ),
        const PeykGap.vertical(PeykGapSize.betweenRows),
      ],
    );
  }
}
