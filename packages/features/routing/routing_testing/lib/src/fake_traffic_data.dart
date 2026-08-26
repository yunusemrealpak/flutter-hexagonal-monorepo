import 'package:core_kernel/core_kernel.dart';
import 'package:routing_api/routing_api.dart';

/// A `TrafficDataPort` whose answer a test chooses.
///
/// Both the profile and the failure are settable, because a use case has to be
/// tested in both worlds: with traffic data, where the estimates reflect it,
/// and without, where the route is still planned against
/// `TrafficProfile.assumed`. The second is the one that runs in a tunnel.
final class FakeTrafficData implements TrafficDataPort {
  /// Creates a fake reporting the given profile.
  FakeTrafficData({this._profile = TrafficProfile.assumed});

  TrafficProfile _profile;
  RoutingFailure? _failure;

  /// Every instant this port was asked about, oldest first.
  ///
  /// Recorded because the port takes `at` rather than reading a clock, and
  /// that is a property worth asserting: a dispatcher planning tomorrow
  /// morning's routes at five in the afternoon wants tomorrow morning's
  /// traffic.
  final List<DateTime> askedAbout = [];

  /// Sets the profile this port reports, clearing any failure.
  void reports(TrafficProfile profile) {
    _profile = profile;
    _failure = null;
  }

  /// Makes every call fail until [reports] is called again.
  // ignore: use_setters_to_change_properties
  void failsWith(RoutingFailure failure) => _failure = failure;

  @override
  Future<Result<TrafficProfile, RoutingFailure>> around(
    GeoPoint area, {
    required DateTime at,
  }) async {
    askedAbout.add(at);
    final failure = _failure;
    return failure != null ? Failed(failure) : Success(_profile);
  }
}
