/// The routing adapters: two answers to one port, the cache, the device's
/// position, and the mappers between them.
///
/// **This package is where scenario 4 becomes two files.**
/// `LocalHeuristicOptimizer` and `RemoteSolverOptimizer` both implement
/// `RouteOptimizerPort`, both pass `runRouteOptimizerContract`, and
/// `routing_application` cannot tell them apart. `app_courier` binds the
/// first, `app_dispatcher` the second, and no use case changes.
///
/// The remote one **validates before it asks**, using the same constraint
/// rules the local one uses. The obvious reason is not to spend a request on a
/// question with no answer; the load-bearing one is that a port's contract
/// cannot be delegated to somebody else's server. A solver run by another team
/// is free to truncate a route that exceeds `maxStops`, and an adapter that
/// relayed whatever came back would pass the contract kit on Monday and fail
/// it after their deploy on Tuesday.
///
/// **`DeviceLocationStream` is where a fix becomes a place.** A `GeoFix`
/// carries an accuracy radius; a `GeoPoint` does not, because routing needs
/// somewhere a courier can be sent rather than a measurement with error bars.
/// A reading too vague to use is refused rather than forwarded — the
/// difference between "I do not know where you are" and "you are somewhere
/// over there" is a wrong-turn alert for a courier sitting still.
///
/// **This package depends on the Flutter SDK**, transitively through
/// `location_service`, which needs it for the plugin it registers. That is
/// what binding a device capability costs, and it is visible: the tests here
/// run under the Flutter test runner rather than `dart test`. The pure Dart
/// half of the feature — `routing_api` and `routing_application`, where the
/// rules live — is untouched by it.
library;

export 'src/device_location_stream.dart';
export 'src/key_value_route_cache.dart';
export 'src/local_heuristic_optimizer.dart';
export 'src/remote_solver_optimizer.dart';
export 'src/rest_traffic_data.dart';
export 'src/route_dto.dart';
export 'src/route_mapper.dart';
