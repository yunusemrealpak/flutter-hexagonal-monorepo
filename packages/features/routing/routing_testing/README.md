# routing_testing

Fakes, fixtures and the contract kits for routing — including the one that makes scenario 4 checkable.

## `runRouteOptimizerContract`

Three implementations of `RouteOptimizerPort` run this suite:

| Implementation | Where | Run in |
|---|---|---|
| `LocalHeuristicOptimizer` | on the device | `routing_infrastructure` |
| `RemoteSolverOptimizer` | on a server | `routing_infrastructure` |
| `FakeRouteOptimizer` | in a test | here |

One description of what an optimiser must do, three answers held to it. That is scenario 4 as a checked fact rather than a claim in a document.

### What it asserts, and what it deliberately does not

It asserts that every answer is a **valid permutation** under the request's constraints: every stop exactly once, nothing invented, anchors honoured, impossible requests refused, the same request twice giving the same answer.

It says **nothing about which** permutation. *"A shorter route"* is precisely the axis the implementations are meant to differ on — a kit that pinned the ordering would fail the moment the remote solver got better, which is the moment it was supposed to be earning its keep.

Quality is asserted where quality belongs: in each implementation's own tests, against its own promises. `LocalHeuristicOptimizer` claims to beat the input order on a route with an obvious detour in it, and proves that next to itself.

One assertion is worth singling out. *"Is accepted by the domain as a sequence over those stops"* runs `StopSequence.over` on the answer — the same three checks the domain runs on a dispatcher's manual reorder. An optimiser is held to the standard a human is.

## `FakeRouteOptimizer` is a fake, not a stub

It keeps the order it is given — but it really validates constraints, really refuses a stop it cannot place, and really honours the anchors, which is why it passes the kit alongside the two real implementations.

That it can do so **in about thirty lines** is itself the evidence that the kit's rules are about *correctness* rather than about *quality*. A rule that only a real solver could satisfy would have been a rule in the wrong place.

Keeping the input order is the point of it: a test running against this optimiser is testing the use case, and the order it gets back is the order it put in. A test that needs the heuristic runs against the heuristic.

## The depot is in Istanbul, not at (0, 0)

At the equator a degree of longitude and a degree of latitude are the same distance. Anywhere else they are not.

A fixture at the origin hides a whole class of latitude-scaling mistakes in whatever consumes it — starting with a haversine that forgot its `cos(latitude)` term, which is wrong by a quarter at this latitude and by nothing at all at the fixture's.

## What else is here

- **`InMemoryRouteCache`** — also a product adapter: `app_dispatcher` binds it, because an operator's plans are read from a server every time the board opens.
- **`FakeTrafficData`** — records the instant it was asked about, because the port takes `at` rather than reading a clock, and a dispatcher planning tomorrow morning's routes at five in the afternoon wants tomorrow morning's traffic.
- **`FakeLocationStream`** — positions are pushed by hand, so a deviation test is a *statement* rather than a simulation whose outcome depends on how long it ran.
- **`runRouteCacheContract`** — smaller, and the assertion in it a courier notices is *"reads back the order, not just the stops"*: somebody restarting the app in a basement has to get the route they were driving, not an arbitrary permutation of the same parcels.

## Why `test` is a runtime dependency

A contract kit *is* tests: it calls `group` and `test` from `lib/`. Leaving `test` in `dev_dependencies` would make that a `dev_dependency_in_lib` violation, and rightly so.

## What it may depend on

`core_kernel`, `core_ports`, `core_testing`, `routing_api`, `identity_api`, `shipments_api`, and `test` at runtime.

## What must never live here

- **Any implementation package.** A fake that depended on `routing_application` would break every time those use cases were refactored, which is the whole reason a contract package is separate from the code that satisfies it.
- **An assertion about route quality in a contract kit.** It belongs beside the implementation that promises it.
