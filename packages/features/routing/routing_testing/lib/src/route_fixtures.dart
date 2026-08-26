import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';
import 'package:routing_api/routing_api.dart';

/// Fixtures for routing, shared by this package's contract kits and by every
/// package that consumes them.
///
/// Everything here is deterministic and nothing calls `DateTime.now()` — rule
/// A1. A route whose estimates depend on when the suite ran is a route no
/// assertion can pin down.
abstract final class RouteFixtures {
  /// The instant every fixture measures from.
  static final DateTime noon = DateTime.utc(2026, 3, 14, 12);

  /// The depot, roughly on the Asian side of Istanbul.
  ///
  /// Real-ish coordinates rather than `(0, 0)`. At the equator a degree of
  /// longitude and a degree of latitude are the same distance and anywhere
  /// else they are not, so a fixture at the origin hides a whole class of
  /// latitude-scaling mistakes in whatever consumes it.
  static final GeoPoint depot = _unwrap(
    GeoPoint.at(latitude: 40.9900, longitude: 29.0300),
  );

  /// A point offset from [depot], in degrees.
  ///
  /// A hundredth of a degree is roughly a kilometre, which is enough to make
  /// orderings differ without making the numbers unreadable in a failure
  /// message.
  static GeoPoint near({double east = 0, double north = 0}) => _unwrap(
    GeoPoint.at(
      latitude: depot.latitude + north,
      longitude: depot.longitude + east,
    ),
  );

  /// A courier, by identifier.
  static ActorId courier([String raw = 'courier-1']) =>
      _unwrap(ActorId.parse(raw));

  /// A stop offset from the depot.
  static Stop stop(
    String id, {
    double east = 0,
    double north = 0,
    Duration service = const Duration(minutes: 5),
    String? shipmentId,
    TravelWindow? window,
  }) => _unwrap(
    Stop.place(
      id: id,
      label: 'Stop $id',
      latitude: depot.latitude + north,
      longitude: depot.longitude + east,
      shipmentId: shipmentId,
      serviceTime: _unwrap(ServiceTime.of(service)),
      window: window,
    ),
  );

  /// A stop identifier.
  static StopId stopId(String raw) => _unwrap(StopId.parse(raw));

  /// A request over [stops], departing at [noon] from [depot].
  static OptimisationRequest request(
    List<Stop> stops, {
    List<RouteConstraint> constraints = const [],
    TrafficProfile traffic = TrafficProfile.assumed,
    DateTime? departAt,
  }) => OptimisationRequest(
    origin: depot,
    stops: stops,
    departAt: departAt ?? noon,
    traffic: traffic,
    constraints: constraints,
  );

  /// A plan over [stops], in the order given.
  static RoutePlan plan(
    List<Stop> stops,
    List<String> order, {
    String id = 'plan-1',
    DateTime? departAt,
  }) => _unwrap(
    RoutePlan.of(
      id: _unwrap(RoutePlanId.parse(id)),
      courier: courier(),
      origin: depot,
      stops: stops,
      sequence: _unwrap(
        StopSequence.over(stops, [for (final s in order) stopId(s)]),
      ),
      departAt: departAt ?? noon,
    ),
  );

  static T _unwrap<T, F>(Result<T, F> result) =>
      result.fold((value) => value, (failure) => throw StateError('$failure'));
}
