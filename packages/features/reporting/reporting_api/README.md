# reporting_api

The reporting contract: what a day of the operation adds up to, and the port that keeps the running total.

## The tally holds outcomes per parcel, not counters

Every number on `OperationTally` — `delivered`, `failed`, `returned`, `total`, `successRate` — is computed from a `Map<ShipmentId, ShipmentOutcome>` on read. A stored counter beside the thing it counts is a state that can disagree with itself, and it disagrees silently. It is the same reason `LoadCount` derives its discrepancy in `vehicle_inventory`.

Two behaviours fall out of it, and the operation needs both:

- **Recording the same parcel twice changes nothing.** A read model built from events is exposed to the same event arriving twice; a counter would have counted it twice.
- **A parcel can change its mind.** Failed at eleven, delivered at four, counted once as delivered. A pair of counters would have to remember to decrement one of them.

The cost is a row per parcel per day. For an operation counting hundreds that is a few kilobytes; for one counting millions it is the point at which the store moves behind an API, which the port makes a composition-root change.

## The facade is read-only

`reporting_core` builds these totals by listening to domain events. Nothing outside the feature tells it what happened, and a `record` method here would be an invitation for a screen to add a number the operation never produced.

## `ShipmentOutcome` has no "in progress"

A parcel still out is not in the tally at all. A fourth member for it would put every undelivered parcel in the denominator of a success rate somebody is watching at eleven in the morning, and the number would climb through the day for no reason anybody caused.

## A day is UTC, and that is a decision with a cost

A round that runs past local midnight is split across two days. The alternative — attributing by the courier's local time — makes a tally that cannot be summed across a fleet without knowing where every courier was standing, and makes yesterday's total change when somebody travels.

`ReportingDay.parse` needs two guards a naive one misses: `DateTime.tryParse` is **lenient** (it reads `2026-13-01` as January 2027) and **local** (a bare date east of Greenwich becomes an instant whose UTC day is the day before). Parsing at midnight UTC and comparing the spelling that comes back is what turns both into a refusal rather than a day silently off by one.

## What it may depend on

`core_kernel`, `shipments_api`

That list is section 2 of [`docs/DEPENDENCY_RULES.md`](../../../../docs/DEPENDENCY_RULES.md), one row. One identifier crosses; no model does. There is no `identity_api` here at all — the tally is the operation's, not a person's, and per-courier figures would be a different question.

## What must never live here

- **A stored count.** See above.
- **A `record` on the facade.** See above.
- **An implementation of `TallyStore`.** Rule S8.
- **A currency figure.** Money is `payments`'; a reporting feature that started summing it would be a second, quietly diverging ledger.

## Code generation

None.
