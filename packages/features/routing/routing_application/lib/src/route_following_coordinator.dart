import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';
import 'package:routing_api/routing_api.dart';

import 'recalculate_on_deviation.dart';
import 'route_channel.dart';
import 'route_reads.dart';

/// `RouteFollowing`'s implementation: the vehicle's half of a route.
///
/// **This is the class an app should not be able to build unless its device is
/// on the route.** `RecalculateOnDeviation` holds a `LocationStreamPort`, and
/// that port reports the position of whatever machine the app is running on.
/// Composing it at a desk answers a courier's question with the desk's
/// coordinates.
///
/// Before phase 8 there was one coordinator taking all four use cases, so
/// every app had to supply this one to get any of routing at all. Splitting
/// the constructor is what turned that from a doc comment into a compiler
/// error.
final class RouteFollowingCoordinator implements RouteFollowing {
  /// Creates the coordinator over its use cases.
  RouteFollowingCoordinator({
    required this._nextStop,
    required this._recalculate,
    required this._channel,
  });

  final NextStop _nextStop;
  final RecalculateOnDeviation _recalculate;
  final RouteChannel _channel;

  @override
  Future<Result<StopId?, RoutingFailure>> nextStop({
    required ActorId courier,
    required Set<StopId> visited,
  }) => _nextStop((courier: courier, visited: visited));

  @override
  Future<Result<RoutePlan, RoutingFailure>> recalculateOnDeviation({
    required ActorId courier,
    required Set<StopId> visited,
  }) => _channel.announce(_recalculate((courier: courier, visited: visited)));
}
