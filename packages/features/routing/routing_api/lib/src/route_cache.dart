import 'package:core_kernel/core_kernel.dart';

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
///
/// **The courier arrives as a `String`, not as an `ActorId`, and that is the
/// same choice `ShipmentGateway.manifestFor` makes.** A driven port is
/// answered by an adapter, and section 2 forbids an adapter from seeing
/// another feature at all — so a port whose signature named `ActorId` would be
/// a port its own adapter could not implement without breaking the rule. The
/// typed identity belongs on the driving side, where `RoutePlanning` takes an
/// `ActorId` and a use case — the layer allowed to see both features — does
/// the crossing.
///
/// It is primitive obsession only if you read the port in isolation. Read as
/// a pair with the driving ports, it is the boundary doing its job: the
/// vocabulary narrows on the way out and widens on the way in.
abstract interface class RouteCache {
  /// The plan stored for the courier with this identifier, or `NoPlan` when
  /// there is none.
  ///
  /// A failure rather than a nullable plan, because every caller that has no
  /// plan has to say so, and a null makes each of them invent the same
  /// sentence.
  Future<Result<RoutePlan, RoutingFailure>> read(String courierId);

  /// Stores [plan], replacing whatever this courier had.
  ///
  /// The whole plan rather than a key and a payload: the plan already knows
  /// whose it is, and a signature that took both would let the two disagree.
  Future<Result<void, RoutingFailure>> write(RoutePlan plan);

  /// Forgets this courier's plan.
  ///
  /// Clearing what is not there succeeds. A sign-out that ran twice is not an
  /// error, and an implementation that made it one would leave a screen
  /// reporting a failure for work that is already done.
  Future<Result<void, RoutingFailure>> clear(String courierId);
}
