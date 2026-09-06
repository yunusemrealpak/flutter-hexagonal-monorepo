import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routing_api/routing_api.dart';

import '../routing_strings.dart';
import 'route_bloc.dart';
import 'route_event.dart';
import 'route_view_state.dart';

/// The route, in the order it will be driven.
///
/// **The same widget in both apps, over two different optimisers.** A courier
/// in a tunnel is looking at a nearest-neighbour ordering their phone
/// computed; a dispatcher is looking at a solver's answer from a data centre.
/// Nothing here can tell the difference, because both arrive as a `RoutePlan`
/// through `RoutePlanning` — which is what scenario 4 is worth once you are
/// past the port itself.
///
/// **Whether the driving order can be changed is read from the bloc's type**,
/// not from a flag. A `SupervisedRouteBloc` holds `RouteSupervision` and a
/// `FollowedRouteBloc` does not, so the reorder affordance appears exactly
/// when the app composed something that can answer it. The previous
/// `reorderable` boolean said what the *viewer* may do; the app still decides
/// that by resolving the route's `requiredPermission` through
/// `PermissionChecker` before this screen is reached.
///
/// **What `buildWhen` compares here is the plan's identity, not the state's
/// type.** `RouteReady` follows itself for two very different reasons: a stop
/// was marked arrived, which changes one tile, and a replan arrived, which
/// changes every row. A plan is immutable, so a different object is a
/// different route and the same object cannot have changed — and the
/// per-stop marks that move without a new plan are selected individually
/// below.
final class RouteScreen extends StatefulWidget {
  /// Creates the screen. The bloc comes from the tree above it.
  const RouteScreen({super.key});

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
    // Both, and in this order: the subscription is what redraws when somebody
    // else replans this courier, and the read is what puts a route on screen
    // now. Neither is awaited — the answers arrive as states.
    context.read<RouteBloc>()
      ..add(const RouteWatched())
      ..add(const RouteRequested());
  }

  @override
  Widget build(BuildContext context) {
    final strings = PeykStrings.of(context);

    return PeykScreen(
      title: strings.resolve(RoutingStrings.title),
      body: BlocBuilder<RouteBloc, RouteViewState>(
        // A new plan redraws the list; an arrival does not, because the marks
        // it moves are selected per stop below.
        buildWhen: (previous, current) => switch ((previous, current)) {
          (RouteReady(plan: final before), RouteReady(plan: final after)) =>
            !identical(before, after),
          _ => previous.runtimeType != current.runtimeType,
        },
        builder: (context, state) => switch (state) {
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
          RouteReady(:final plan) => _Stops(plan: plan),
          RouteFailed(:final failure) => PeykFailureView(
            message: strings.resolve(
              RouteScreen.describe(failure),
              arguments: RouteScreen.argumentsFor(failure),
            ),
            onRetry: () =>
                context.read<RouteBloc>().add(const RouteRequested()),
          ),
        },
      ),
    );
  }
}

final class _Stops extends StatelessWidget {
  const _Stops({required this.plan});

  final RoutePlan plan;

  @override
  Widget build(BuildContext context) {
    // The estimates are already in visiting order, so the list is walked from
    // them rather than from the sequence: one source for the order and the
    // times means the two cannot disagree about which stop is third.
    final byId = {for (final stop in plan.stops) stop.id: stop};
    // The affordance is read from the type. A courier's bloc holds no
    // `RouteSupervision`, so there is nothing for it to call and the screen
    // cannot draw it by mistake.
    final canReorder = context.read<RouteBloc>() is SupervisedRouteBloc;
    final strings = PeykStrings.of(context);

    return ListView(
      children: [
        // An advisory rather than a failure view: the route below is drivable,
        // it is just not fresh. Replacing the stops with an error page would
        // stop a courier driving a route that works.
        //
        // Selected, because a refused reorder keeps the plan it refused —
        // which is exactly the case the list above deliberately does not
        // rebuild for.
        BlocSelector<RouteBloc, RouteViewState, String?>(
          selector: (state) => switch (state) {
            RouteReady(refusal: final refusal?) => strings.resolve(
              RouteScreen.describe(refusal),
              arguments: RouteScreen.argumentsFor(refusal),
            ),
            _ => null,
          },
          builder: (context, label) => label == null
              ? const SizedBox.shrink()
              : PeykChip(label: label, intent: PeykIntent.warning),
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
            canMoveUp: canReorder && index > 0,
          ),
      ],
    );
  }
}

final class _StopTile extends StatelessWidget {
  const _StopTile({
    required this.stop,
    required this.eta,
    required this.canMoveUp,
  });

  final Stop stop;
  final Eta eta;
  final bool canMoveUp;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<RouteBloc>();
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
          //
          // `isNext` is asked of the state per stop rather than computed once
          // for the list, because the rule for what "next" means belongs to
          // `RoutePlan` and a second copy of it here would disagree with the
          // domain's on the day either changed. A route is tens of stops.
          trailing: BlocSelector<RouteBloc, RouteViewState, bool>(
            selector: (state) =>
                state is RouteReady && state.nextStop == eta.stop,
            builder: (context, isNext) => Row(
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
        ),
        Row(
          children: [
            // The one part of a tile an arrival changes. Marking a stop done
            // emits a new `RouteReady` over the same plan, which the list
            // above deliberately ignores — so this is where the redraw has to
            // happen, and it happens for one stop rather than forty.
            BlocSelector<RouteBloc, RouteViewState, bool>(
              selector: (state) =>
                  state is RouteReady && state.visited.contains(eta.stop),
              builder: (context, isDone) => isDone
                  ? PeykChip(
                      label: strings.resolve(RoutingStrings.done),
                      intent: PeykIntent.success,
                    )
                  : PeykButton(
                      label: strings.resolve(RoutingStrings.arrived),
                      onPressed: () => bloc.add(StopArrived(eta.stop)),
                      tone: PeykButtonTone.primary,
                    ),
            ),
            if (canMoveUp) ...[
              const PeykGap.horizontal(PeykGapSize.betweenLines),
              PeykButton(
                label: strings.resolve(RoutingStrings.moveUp),
                onPressed: () => bloc.add(StopMovedUp(eta.stop)),
              ),
            ],
          ],
        ),
        const PeykGap.vertical(PeykGapSize.betweenRows),
      ],
    );
  }
}
