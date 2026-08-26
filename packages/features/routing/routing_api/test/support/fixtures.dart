import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';
import 'package:routing_api/routing_api.dart';

/// A fixed instant every test in this package measures from.
///
/// A constant rather than a clock. Nothing here calls `DateTime.now()` — rule
/// A1 — and a plan whose estimates take `departAt` as a parameter is one whose
/// arrival times can be asserted exactly.
final noon = DateTime.utc(2026, 3, 14, 12);

/// Unwraps a [Result] in test setup, where a failure means the fixture itself
/// is wrong and the test has nothing left to say.
T unwrap<T, F>(Result<T, F> result) =>
    result.fold((value) => value, (failure) => throw StateError('$failure'));

/// A courier, by identifier.
ActorId courier([String raw = 'courier-1']) => unwrap(ActorId.parse(raw));

/// The depot, roughly on the Asian side of Istanbul.
///
/// Real-ish coordinates rather than `(0, 0)`, because a haversine at the
/// equator hides a whole class of latitude-scaling mistakes: at the equator a
/// degree of longitude and a degree of latitude are the same distance, and
/// anywhere else they are not.
final GeoPoint depot = unwrap(
  GeoPoint.at(latitude: 40.9900, longitude: 29.0300),
);

/// A point [east] degrees east and [north] degrees north of the depot.
GeoPoint near({double east = 0, double north = 0}) => unwrap(
  GeoPoint.at(
    latitude: depot.latitude + north,
    longitude: depot.longitude + east,
  ),
);

/// A stop at a given offset from the depot.
///
/// The offsets are in degrees, so a hundredth of a degree is roughly a
/// kilometre — enough to make orderings differ without making the numbers
/// unreadable in a failure message.
Stop stopAt(
  String id, {
  double east = 0,
  double north = 0,
  Duration service = const Duration(minutes: 5),
  TravelWindow? window,
}) => unwrap(
  Stop.place(
    id: id,
    label: 'Stop $id',
    latitude: depot.latitude + north,
    longitude: depot.longitude + east,
    serviceTime: unwrap(ServiceTime.of(service)),
    window: window,
  ),
);

/// A sequence over [stops], in the order given.
StopSequence sequence(List<Stop> stops, List<String> order) => unwrap(
  StopSequence.over(stops, [for (final id in order) unwrap(StopId.parse(id))]),
);

/// A plan over [stops] in the order given, departing at [noon].
RoutePlan planOver(
  List<Stop> stops,
  List<String> order, {
  DateTime? departAt,
  TrafficProfile traffic = TrafficProfile.assumed,
}) => unwrap(
  RoutePlan.of(
    id: unwrap(RoutePlanId.parse('plan-1')),
    courier: courier(),
    origin: depot,
    stops: stops,
    sequence: sequence(stops, order),
    departAt: departAt ?? noon,
    traffic: traffic,
  ),
);
