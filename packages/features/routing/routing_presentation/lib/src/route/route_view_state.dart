import 'package:routing_api/routing_api.dart';

/// What the route screen can be showing.
///
/// Sealed and hand-written, in a package that has no code generation at all.
/// A presentation package with five small state cases and no annotated type
/// gets no `build.yaml` and no `build_runner` dependency, which CLAUDE.md §7.6
/// calls the cheapest configuration rather than a missing one.
///
/// Five cases rather than one class with `isLoading`, `plan` and `failure` on
/// it. The flat shape lets a widget be handed a loading state that also has a
/// plan and a failure, and the day two of those are set at once nobody can say
/// what should be on screen.
sealed class RouteViewState {
  const RouteViewState();
}

/// Nothing has been asked for yet.
final class RouteIdle extends RouteViewState {
  /// Creates the state.
  const RouteIdle();
}

/// The route is being read.
final class RouteLoading extends RouteViewState {
  /// Creates the state.
  const RouteLoading();
}

/// This courier has no route yet.
///
/// A state of its own rather than a [RouteFailed] carrying `NoPlan`. The port
/// has to answer *something* when nothing is cached, and a failure is the only
/// honest answer it can give; but on screen "nobody has planned your morning
/// yet" is where a courier starts every day, and rendering it as an error
/// sends them looking for a problem that does not exist.
///
/// The translation from the one to the other happens in the controller, which
/// is the layer that knows what the screen is for.
final class RouteUnplanned extends RouteViewState {
  /// Creates the state.
  const RouteUnplanned();
}

/// A route arrived, and this is what it looks like right now.
final class RouteReady extends RouteViewState {
  /// Creates the state.
  const RouteReady(this.plan, {this.visited = const {}, this.refusal});

  /// The route, in the order it will be driven.
  final RoutePlan plan;

  /// The stops the courier has already been to.
  ///
  /// Held beside the plan rather than inside it, because a plan is what was
  /// *decided* and this is what has *happened*. Folding arrivals into the plan
  /// would mean a new plan identifier every time a courier finished a stop,
  /// and the route a dispatcher is looking at would change identity under
  /// them for a reason that has nothing to do with routing.
  final Set<StopId> visited;

  /// An edit the domain refused, or `null`.
  ///
  /// A refused resequence leaves [plan] untouched and still correct — the
  /// domain declined to change it, so what is on screen is the truth rather
  /// than a stale copy of it. Dropping to a failure state instead would blank
  /// a valid route because somebody dragged a row to a place it could not go.
  final RoutingFailure? refusal;

  /// The stop the courier should be heading for, or `null` when the route is
  /// finished.
  ///
  /// Delegated to `RoutePlan`, which is where the rule lives. Walking
  /// `plan.sequence.order` here instead would give the UI its own opinion
  /// about what "next" means, and the day the domain's changes the two would
  /// disagree without either being obviously wrong.
  StopId? get nextStop => plan.nextStopAfter(visited);
}

/// The route could not be read.
final class RouteFailed extends RouteViewState {
  /// Creates the state.
  const RouteFailed(this.failure);

  /// What went wrong, in routing's own words.
  ///
  /// A `RoutingFailure`, not a `String`. Turning it into a message is this
  /// layer's job and it happens at the widget, where the locale is known;
  /// carrying a formatted string here would put English in a state object and
  /// make it untranslatable a phase later.
  final RoutingFailure failure;
}
