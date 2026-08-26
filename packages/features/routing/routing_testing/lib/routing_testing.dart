/// Fakes, fixtures and contract kits for routing.
///
/// **The kit that matters is `runRouteOptimizerContract`.** Three
/// implementations of `RouteOptimizerPort` run it: the device-side heuristic
/// and the remote solver in `routing_infrastructure`, and `FakeRouteOptimizer`
/// here. That is scenario 4 made checkable — one description of what an
/// optimiser must do, and three answers held to it.
///
/// It asserts that every answer is a valid *permutation* under the request's
/// constraints, and says nothing about which one. "A shorter route" is exactly
/// the axis the implementations are meant to differ on, and a kit that pinned
/// the ordering would fail the moment the remote solver got better — which is
/// the moment it was supposed to be earning its keep. Quality is asserted in
/// each implementation's own tests, against its own promises.
///
/// **Fakes.** `FakeRouteOptimizer` keeps the order it is given but really
/// validates constraints and really refuses a stop it cannot place, which is
/// why it passes the kit alongside the real two — and which makes it evidence
/// that the kit's rules are about correctness rather than quality.
/// `InMemoryRouteCache` is also a product adapter: `app_dispatcher` binds it.
/// `FakeTrafficData` and `FakeLocationStream` are pushed by hand, so a
/// deviation test is a statement rather than a simulation.
///
/// **Fixtures.** `RouteFixtures` places its depot in Istanbul rather than at
/// the origin. At the equator a degree of longitude and a degree of latitude
/// are the same distance and anywhere else they are not, so a fixture at
/// `(0, 0)` hides a whole class of latitude-scaling mistakes.
///
/// `test` is a runtime dependency of this package rather than a dev one,
/// because a contract kit *is* tests — it calls `group` and `test` from
/// `lib/`.
library;

export 'src/fake_location_stream.dart';
export 'src/fake_route_optimizer.dart';
export 'src/fake_traffic_data.dart';
export 'src/in_memory_route_cache.dart';
export 'src/route_cache_contract.dart';
export 'src/route_fixtures.dart';
export 'src/route_optimizer_contract.dart';
