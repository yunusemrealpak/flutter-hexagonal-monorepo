# reporting_presentation

The reporting UI: the board a dispatcher watches the day on.

## The permission is checked before the read, not after

A screen that fetched the figures and hid them afterwards would have put them in memory on a device whose owner may not see them, and would have told the server which days somebody was interested in. `ReportController.load` answers `ReportForbidden` without asking the facade anything.

`ReportForbidden` is its own state rather than an empty board, because the two mean opposite things: a dispatcher with an empty board is looking at a quiet morning, and a courier who reached this screen is looking at something that is not theirs to see.

This is scenario 6 for the fifth time, and the stand-in in the test suite is the same four lines as in `payments_presentation`, `delivery_presentation`, `shipments_presentation_dispatcher` and `incidents_presentation`.

## The route is guarded even though no courier app will include it

"We will not put it in that app" is a decision somebody can reverse in a pull request. The guard is what makes reversing it safe.

## Range totals are summed here, not on the entity

`ReportReady.total` and `ReportReady.delivered` add up the days on screen. `OperationTally` is about **one day**; a method on it that only made sense over a list would be a method in the wrong place.

## No chart

A chart is the first thing `design_system` will bring in phase 7, and one hand-painted here would be a thing to delete rather than a thing to restyle. The rate is rendered in whole percentage points, because a delivery rate quoted to two decimals invites somebody to treat a change of 0.03 as news.

## What it may depend on

`core_kernel`, `core_navigation`, `identity_api`, `reporting_api`, `flutter`

That list is section 2 of [`docs/DEPENDENCY_RULES.md`](../../../../docs/DEPENDENCY_RULES.md), one row. `shipments_api` is a **dev** dependency: nothing under `lib/` names a `ShipmentId` — this board counts parcels and never identifies one — but a test has to build a tally, and a tally is keyed by shipment.

## What must never live here

- **`reporting_core`.** Contracts only.
- **A read before the permission check.** See above.
- **A sentence.** Labels are localisation keys; `ReportScreen.describe` is the deliberate exception.

## Code generation

None.
