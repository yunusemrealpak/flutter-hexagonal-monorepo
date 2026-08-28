import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';
import 'package:routing_api/routing_api.dart';

import 'route_channel.dart';
import 'route_reads.dart';

/// `RouteSupervision`'s implementation: a desk overriding a driving order.
///
/// One use case and a channel. It is a whole class for one method because the
/// alternative — leaving `resequence` on the interface both audiences hold —
/// is what made every app bind every port behind the feature.
final class RouteSupervisionCoordinator implements RouteSupervision {
  /// Creates the coordinator over its use case.
  RouteSupervisionCoordinator({
    required this._resequence,
    required this._channel,
  });

  final Resequence _resequence;
  final RouteChannel _channel;

  @override
  Future<Result<RoutePlan, RoutingFailure>> resequence({
    required ActorId courier,
    required List<StopId> order,
  }) => _channel.announce(_resequence((courier: courier, order: order)));
}
