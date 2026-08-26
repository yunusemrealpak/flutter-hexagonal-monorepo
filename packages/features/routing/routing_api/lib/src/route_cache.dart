import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';

import 'route_plan.dart';
import 'routing_failure.dart';

/// Keeps the plan a courier is currently driving, on the device.
///
/// The plan is the one thing this feature cannot afford to lose. A courier who
/// restarts the app in a basement has to get their stop list back without a
/// server and without an optimiser — which is why the cache is a port of its
/// own rather than something the gateway does on the side.
///
/// One plan per courier, replaced rather than accumulated. A history of plans
/// is a reporting concern and belongs on a server; keeping every morning's
/// route on a phone would grow without bound and answer no question the device
/// asks.
abstract interface class RouteCache {
  /// The plan stored for [courier], or `NoPlan` when there is none.
  ///
  /// A failure rather than a nullable plan, because every caller that has no
  /// plan has to say so, and a null makes each of them invent the same
  /// sentence.
  Future<Result<RoutePlan, RoutingFailure>> read(ActorId courier);

  /// Stores [plan], replacing whatever this courier had.
  Future<Result<void, RoutingFailure>> write(RoutePlan plan);

  /// Forgets this courier's plan.
  ///
  /// Clearing what is not there succeeds. A sign-out that ran twice is not an
  /// error, and an implementation that made it one would leave a screen
  /// reporting a failure for work that is already done.
  Future<Result<void, RoutingFailure>> clear(ActorId courier);
}
