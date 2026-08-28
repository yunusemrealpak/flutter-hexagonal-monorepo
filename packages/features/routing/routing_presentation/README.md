# routing_presentation

The routing UI: one courier's route, in the order it will be driven.

This is where scenario 4 stops being about a port. `RouteScreen` renders a `RoutePlan`, and nothing in this package can find out which optimiser produced it — a courier in a tunnel is looking at a nearest-neighbour ordering their own phone computed, a dispatcher is looking at a solver's answer from a data centre, and the two apps share every line of this package.

## What it may depend on

`core_kernel`, `core_navigation`, `identity_api`, `routing_api`, the Flutter SDK

That list is section 2 of [`docs/DEPENDENCY_RULES.md`](../../../../docs/DEPENDENCY_RULES.md), one row. A dependency outside it is a violation rather than an exception; `dart run melos run arch:check` will say which rule and how to fix it.

`identity_api` is here for one type: `ActorId`. Routing has a single presentation package and the two apps point it at different subjects — a courier at their own afternoon, a dispatcher at somebody else's — so `RouteController` takes the courier through its constructor instead of reading one from `SessionReader`, which would be right in one app and wrong in the other. An identifier crosses a feature boundary and a model does not; section 2.1 is the rule.

## What must never live here

- **`routing_application`, `routing_infrastructure` or any `_core`.** Presentation knows the vocabulary, not the use cases and not the adapters; the app wires them together.
- **Anything from `platform/*`.**
- **A second opinion about the domain.** "Which stop is next" is `RoutePlan.nextStopAfter`, "is this order drivable" is `StopSequence.over`. Recomputing either here would give the UI a view that can disagree with the domain without either being obviously wrong.
- **A colour, a spacing value or a date format of its own.** Colours and spacing come from `design_system`. Times are not formatted here at all: `RoutingStrings.summary` and `RoutingStrings.arrivesAt` take UTC `DateTime` arguments and the app turns them into a wall clock, because doing that needs a timezone and a locale and the app is the only thing with both.

## Code generation

There is no `build.yaml` and no `build_runner` dependency, because nothing here is generated — that is the cheapest configuration, not a missing one. The state union is five hand-written classes, which is less code than the annotations that would produce it. When type-safe routes arrive with the apps, add a `build.yaml` that enables `go_router_builder` and narrows it with `generate_for: [lib/src/**.dart]`.

## What is in here

| File | What it is |
|---|---|
| `route_controller.dart` | Holds `RoutingFacade` and one `ActorId`; turns port answers into states. |
| `route_view_state.dart` | The sealed union a widget renders exhaustively. |
| `route_screen.dart` | The stop list, its markers, and the failure sentences. |
| `routing_routes.dart` | Two destinations, one screen; the difference between them is a permission. |

## Two failures are advisories, not failure pages

`RouteScreen.isAdvisory` names them: `PositionUnavailable` and `RoutingUnavailable`. Both mean "this is the route, just not a fresh one", and a courier shown an error page for either has been stopped from driving a route that is perfectly drivable. They are drawn as a warning chip above the stops — which is what `RouteReady.refusal` has always carried, now with a component that makes the difference visible.

The other five replace the screen, because after any of them there is nothing to drive.
