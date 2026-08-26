# routing_infrastructure

The routing adapters: two answers to one port, the cache, the device's position, and the mappers between them.

## Scenario 4, as two files

`LocalHeuristicOptimizer` and `RemoteSolverOptimizer` both implement `RouteOptimizerPort`, both pass `runRouteOptimizerContract`, and `routing_application` cannot tell them apart. `app_courier` binds the first, `app_dispatcher` the second, and no use case changes.

```dart
// test/optimizers_pass_the_contract_test.dart — the whole scenario, in two lines
runRouteOptimizerContract(LocalHeuristicOptimizer.new);
runRouteOptimizerContract(() => RemoteSolverOptimizer(transport: _SortingSolver()));
```

### `LocalHeuristicOptimizer`

Nearest neighbour, then a 2-opt improvement pass. Neither is state of the art and neither claims to be — nearest neighbour typically lands 20–25% above optimal and 2-opt removes the crossings, which is where most of that lives. The point of the port is that the operation can buy a better answer without touching a use case; the point of this class is that it is a *usable* answer with no network at all.

It is pure computation — no clock, no randomness, no I/O — which makes it the cheapest thing in the workspace to test. Its own tests assert what it *promises*: a chain of stops comes back in order, a route with a detour in it beats the input order, and 2-opt is never worse than greedy alone.

**Determinism is a contract requirement.** Ties break on the stop identifier and the improvement pass is bounded at a fixed sweep count. An optimiser that reordered a route every time a screen refreshed would move a courier's next stop while they were reading it.

### `RemoteSolverOptimizer` validates before it asks

The constraints are checked on the device, using the same `List<RouteConstraint>` extension the local optimiser uses. An impossible request never leaves.

There is no coordinate check in either optimiser, and there used to be. `Stop.place` refuses a stop without coordinates, so by the time a request reaches an optimiser every stop on it carries a `GeoPoint` — an unconstructible state needs no guard.

The obvious reason is not to spend a request on a question with no answer. The load-bearing one:

> **A port's contract cannot be delegated to somebody else's server.**

A solver run by another team is free to truncate a route that exceeds `maxStops`. An adapter that relayed whatever came back would pass `runRouteOptimizerContract` on Monday and fail it after their deploy on Tuesday. So the answer is checked too — anchors are re-applied, and a solver that drops or invents a stop gets a `SequenceDoesNotMatch` rather than a route with a missing parcel.

## `DeviceLocationStream`: where a fix becomes a place

A `GeoFix` carries an accuracy radius and the moment the device produced it. A `GeoPoint` carries neither, because routing needs *somewhere a courier can be sent* rather than a measurement with error bars.

**A fix too vague to use is not a position.** Below 250 m of accuracy the reading is refused rather than forwarded. "You are somewhere over there" would have the deviation check report a wrong turn for a courier sitting still.

**The stream drops failures; `current()` reports them.** That is the port's contract. A stream that errored would tear down every listener the first time a courier walked into a car park, and re-subscribing after that is a concern no screen should have to code around.

**All five location failures collapse to `PositionUnavailable`.** `location_service` distinguishes them because a *permission screen* behaves differently about each; routing has one response to all of them — plan without a position. The narrowing is deliberate, and the feature that owns the prompt reads the five.

## `KeyValueRouteCache`, and why not a drift table

A plan is one blob per courier, read whole and written whole, with no query over it. A table would buy indexing nothing asks for and cost a migration every time a stop grew a field.

`KeyValueStore`'s own documentation warns against using it for domain data — and that warning is about *entities a feature needs to query*. A cached aggregate fetched only by its owner's identifier is what the store is for. The line is real; this says which side of it this adapter is on rather than assuming.

**The stored plan has no arrival times in it.** The DTO carries the order, the departure instant, the traffic profile and the service times — everything the estimates are derived from — and `RoutePlan.of` recomputes them on read. Persisting the derived values would put a second source of truth on the device, and the day the estimate rule changed, a courier would see yesterday's arithmetic until their cache happened to be rewritten.

`StoreCorrupted` maps to a malformed value and `StoreUnavailable` to an unavailable service, because the two lead somewhere different: one means *ask again later*, the other means *this plan is gone, replan*.

## This package depends on Flutter, and that is visible

`location_service` brings the Flutter SDK with it, for the plugin it registers. So the tests here run under `flutter test` rather than `dart test`.

That is what binding a device capability costs, and it is worth seeing where the cost lands: **`routing_api` and `routing_application` — where every rule in this feature lives — are untouched by it.** The 80% of the suite that runs in milliseconds still does.

## No foreign feature in this pubspec

`core_kernel`, `core_ports`, `http_dio`, `location_service`, `routing_api`, `json_annotation`. That is section 2's row for `feature_infrastructure`, exactly.

It very nearly was not. The mapper has to rebuild the `ActorId` and `ShipmentId` that routing's own contract is expressed in, and the first version reached for `identity_api` and `shipments_api` to do it — which `arch_check` refused, and which read at first like a rule that needed widening.

Two moves removed the need, and neither of them touched a rule:

- **`CourierReference` and `ShipmentReference` in `routing_api`.** They read a foreign identifier and report a bad one as a *routing* failure. `routing_api` is the one layer allowed to see those packages, so it is the one layer that translates — an anticorruption layer in the consuming feature's own contract. `shipments_api` has done this since phase 4.
- **`RouteCache` takes a `String courierId`.** A driven port is answered by an adapter that may not see another feature, so a signature naming `ActorId` is a signature its own adapter cannot implement. `ShipmentGateway.manifestFor` makes the same choice.

`RouteMapper` also chains with `flatMap` rather than binding a local: `final ActorId courier;` would require writing the type name, and the lambda's parameter is inferred. That is the difference between not naming a type and not depending on it — this package does both.

Not `routing_application` either. Section 2 forbids that edge too, and this is where it earns its keep: nothing here can call a use case, so nothing here can quietly grow one.

## What must never live here

- **A rule.** Whether a route has deviated, how an estimate is computed, what a valid sequence is, what makes a `Stop` usable — all of that is `routing_api`'s. This package answers *"what did the solver say"* and *"where is the device"*.
- **A foreign feature, contract included.** Section 2's row, and the readers above are why it has never needed an exception.
- **A DTO in `routing_api`.** Rules I4 and G2.
- **A second haversine.** Distance is `GeoPoint.distanceTo`. Two copies eventually disagree about the length of the same route, and that is drift the contract kit cannot catch.

## Code generation

`build.yaml` enables `json_serializable`, narrowed to `lib/src/**.dart`. `freezed` is absent because it is not a dev dependency here — the domain types these DTOs map to live in `routing_api`.
