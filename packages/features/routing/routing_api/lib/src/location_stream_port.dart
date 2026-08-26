import 'package:core_kernel/core_kernel.dart';

import 'geo_point.dart';
import 'routing_failure.dart';

/// Where the courier is, and where they go next.
///
/// Routing's own port over a capability `platform/location_service` provides.
/// The two are not the same contract and the difference is the point:
/// `LocationSource` speaks in `GeoFix` — an accuracy radius, the moment the
/// device fixed it, a permission that may be denied — and this speaks in
/// `GeoPoint`, which is a *place*. `routing_infrastructure` maps one into the
/// other and decides what a fix too inaccurate to use means.
///
/// That mapping is also where a denied permission becomes
/// `PositionUnavailable`. `routing_application` may not depend on `platform/*`
/// at all, so a use case here could not see a `PermissionState` even if
/// somebody wanted it to — which is the constitution making the right thing
/// the only available thing.
abstract interface class LocationStreamPort {
  /// The device's position now.
  Future<Result<GeoPoint, RoutingFailure>> current();

  /// Positions as they change.
  ///
  /// Implementations emit the current position on subscription where they have
  /// one, so a screen that starts watching mid-shift does not sit blank until
  /// the courier moves.
  ///
  /// The stream carries no failures: a position that cannot be fixed is simply
  /// not emitted. A stream that errored would tear down every listener the
  /// first time a courier walked into a car park, and reconnecting after that
  /// is a concern nobody should have to code around.
  Stream<GeoPoint> positions();
}
