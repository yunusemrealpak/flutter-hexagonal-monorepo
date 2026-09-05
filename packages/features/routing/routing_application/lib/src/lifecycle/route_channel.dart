import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:routing_api/routing_api.dart';

/// The one place a container's route changes are announced.
///
/// It exists because routing's driving surface is three interfaces and its
/// change stream is one fact. `RouteSupervision.resequence` and
/// `RouteFollowing.recalculateOnDeviation` both replace a plan, and a screen
/// watching through `RoutePlanning.changes` has to see either of them — so the
/// stream cannot belong to whichever coordinator happens to be registered.
///
/// A composition root binds one of these and hands it to every routing
/// coordinator it builds. That is the only new thing an app has to know about
/// after the split, and it is the honest price of it: the three roles are
/// separate objects, and one fact they share needs somewhere to live.
final class RouteChannel {
  /// Creates an open channel.
  RouteChannel();

  final StreamController<RoutePlan> _plans =
      StreamController<RoutePlan>.broadcast();

  /// What a screen watches.
  ///
  /// A broadcast stream, so a stop list and a map can both listen.
  Stream<RoutePlan> get plans => _plans.stream;

  /// Runs [work] and announces the plan it produced.
  ///
  /// **Nothing is emitted for a refused call.** The route did not change, and
  /// a screen that redrew on it would flicker for no reason. The rule is here
  /// rather than in each coordinator so that a fourth role cannot forget it.
  Future<Result<RoutePlan, RoutingFailure>> announce(
    Future<Result<RoutePlan, RoutingFailure>> work,
  ) async {
    final result = await work;
    if (result case Success(value: final plan)) _plans.add(plan);
    return result;
  }

  /// Releases the stream.
  ///
  /// Called by the composition root when the container is torn down. The
  /// channel owns the controller, so it is the only thing that can.
  Future<void> dispose() => _plans.close();
}
