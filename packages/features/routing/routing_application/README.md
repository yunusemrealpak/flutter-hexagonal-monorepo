# routing_application

The routing use cases: pure Dart, and blind to which optimiser is behind them.

## That blindness is the payoff

`PlanRoute` holds a `RouteOptimizerPort` and never learns whether the ordering came from a heuristic running on the phone or from a solver in a data centre. `app_courier` and `app_dispatcher` share every line of this package while behaving completely differently in a tunnel.

Every test in here runs against `FakeRouteOptimizer`, which keeps the order it is given. That is deliberate: the order that comes back is the order that went in, so an assertion about caching is not also an assertion about a heuristic. The heuristic's own tests live next to the heuristic.

## The traffic profile is fetched here, not by the optimiser

`RemoteSolverOptimizer` could ask a traffic service. `LocalHeuristicOptimizer` could not. **A port whose two implementations see different inputs is a port whose contract cannot be written down.**

So `PlanRoute` asks `TrafficDataPort` and hands the same profile to whichever optimiser is bound.

A traffic service that cannot be reached does **not** stop a plan. The route is built against `TrafficProfile.assumed`, which still produces a usable *ordering* — and an ordering is what a courier in a tunnel actually needs, even when the times attached to it are guesses.

## `maxDuration` is checked here, and the other constraints are not

The duration follows from the *order*, and the order is what an optimiser is being asked for. Checking the limit before a plan exists would mean checking it against a route nobody has chosen yet.

The anchors and `maxStops` go the other way: they shape the search, so they belong to the optimiser — and the arithmetic all three implementations share lives in `routing_api`, on `List<RouteConstraint>`.

## Two failures handled differently, on purpose

| Use case | The cache write fails | Why |
|---|---|---|
| `PlanRoute` | logged, plan still returned | A courier who has been given a route has been given a route. The cost is a restart that has to ask again, which is much better than an error where a stop list should be. |
| `Resequence` | reported to the caller | A dispatcher told the reorder worked has to be able to rely on the courier seeing it. A plan returned and not stored shows the new order on one screen and the old one on the other. |

## `RecalculateOnDeviation` does not replan on no evidence

Three refusals, and each of them is a bug somebody has shipped:

- **No position → no replan.** A courier in a car park with no fix has not deviated; they are invisible. Replanning here reorders a route because somebody walked into a basement.
- **Finished route → no replan.** There is nothing left to head for.
- **On route → no replan, and the same plan comes back.** A caller does not have to ask twice to find out what to draw, and *whether it is a new plan* is visible in its identifier — which is the reason plans are replaced rather than mutated.

When it does replan, it starts from where the courier actually is and drops the stops already visited. That is the difference between a recalculation and a fresh morning.

The tolerance is a constructor argument with a documented default of 750 m. It has to absorb the difference between a great-circle distance and a road — a city grid roughly doubles one into the other — so a much smaller value reports a deviation on every normal journey, and a much larger one lets a courier finish the wrong district before anybody notices.

## What it may depend on

`core_kernel`, `core_ports`, `identity_api`, `routing_api`. Dev: `core_testing`, `routing_testing`, `test`.

Not `routing_infrastructure`, not `platform/*`. A use case here could not see a `GeoFix` or a `PermissionState` even if somebody wanted it to.

## What must never live here

- **A rule that belongs on the entity.** The estimates, the deviation test and the sequence checks are `RoutePlan`'s. A use case orchestrates; an entity decides.
- **A decision a coordinator makes on its own.** Each of the three delegates to its own use cases and shares one `RouteChannel`.
- **`DateTime.now()`, `Random()`, `print()`.** Rules A1, A2, A4.
