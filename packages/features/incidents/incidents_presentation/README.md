# incidents_presentation

The incidents UI: the board a dispatcher works down, and the form a courier reports from.

## Two destinations, two permissions

Recording an exception at a door and working down the operation's board are not the same authority. `IncidentsRoutes` guards `incidents.report` with `reportIncident` and `incidents.board` with `viewReports`. A single permission would mean either couriers reading every incident in the fleet, or dispatchers unable to record what a phone call just told them.

## Scenario 6, for the fourth time

`IncidentBoardController.canReport` asks `identity_api`'s `PermissionChecker` and learns nothing about roles or grants. The stand-in in this package's test suite is the same four lines as in `payments_presentation`, `delivery_presentation` and `shipments_presentation_dispatcher` — which is what the scenario buys.

The permission is asked **once and read by the widget**, never inside `build`: a check in a build method runs on every frame and turns a question about authority into a question about rendering.

The controller checks it a **second time** before reporting, and that is not belt-and-braces. A controller is reachable from a route as well as from the button the screen has already hidden.

## An empty board says so

`incidents.clear` is its own case rather than an empty `Column`. A screen with nothing on it reads as a screen that failed to load, and a dispatcher would refresh it.

## Severity is a semantics label, for now

`design_system` arrives in phase 7, and severity is the one thing on this screen that a dispatcher reads first — which in a finished product means colour. Until the tokens exist, it is a semantics label: readable by a test and by a screen reader, and impossible to mistake for a design decision that was made.

## What it may depend on

`core_kernel`, `core_navigation`, `identity_api`, `incidents_api`, `shipments_api`, `flutter`

That list is section 2 of [`docs/DEPENDENCY_RULES.md`](../../../../docs/DEPENDENCY_RULES.md), one row. `incidents_core` is not on it.

## What must never live here

- **`incidents_core`.** A presentation package sees contracts, never implementations.
- **`core_ports`.** Not on this row; every instant on screen was stamped by a use case with a `Clock`.
- **A permission check inside `build`.** See above.
- **A sentence.** Labels are localisation keys; `IncidentBoardScreen.describe` is the deliberate exception.

## Code generation

None. Two routes with no parameters do not pay for `go_router_builder`.
