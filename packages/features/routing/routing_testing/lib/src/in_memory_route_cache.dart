import 'package:core_kernel/core_kernel.dart';
import 'package:routing_api/routing_api.dart';

/// A `RouteCache` that really keeps plans, in a map.
///
/// One plan per courier, replaced rather than accumulated — the same rule the
/// port states, honoured here so that a test written against this fake
/// exercises the caller's logic rather than a script of expected calls.
///
/// It is also the cache `app_dispatcher` binds: an operator's plans are read
/// from a server every time the board opens, and a database file on a desktop
/// buys nothing.
final class InMemoryRouteCache implements RouteCache {
  final Map<String, RoutePlan> _byCourier = {};
  final List<RoutingFailure> _queuedFailures = [];

  /// Makes the next call return [failure].
  void failNextWith(RoutingFailure failure) => _queuedFailures.add(failure);

  /// Every plan the cache currently holds.
  List<RoutePlan> get stored => List.unmodifiable(_byCourier.values);

  @override
  Future<Result<RoutePlan, RoutingFailure>> read(String courierId) async {
    final failure = _takeFailure();
    if (failure != null) return Failed(failure);

    final plan = _byCourier[courierId];
    if (plan == null) return Failed(NoPlan(courierId));
    return Success(plan);
  }

  @override
  Future<Result<void, RoutingFailure>> write(RoutePlan plan) async {
    final failure = _takeFailure();
    if (failure != null) return Failed(failure);

    _byCourier[plan.courier.value] = plan;
    return const Success(null);
  }

  @override
  Future<Result<void, RoutingFailure>> clear(String courierId) async {
    final failure = _takeFailure();
    if (failure != null) return Failed(failure);

    // Clearing what is not there succeeds. A sign-out that ran twice is not an
    // error, and an implementation that made it one would leave a screen
    // reporting a failure for work that is already done.
    _byCourier.remove(courierId);
    return const Success(null);
  }

  RoutingFailure? _takeFailure() =>
      _queuedFailures.isEmpty ? null : _queuedFailures.removeAt(0);
}
