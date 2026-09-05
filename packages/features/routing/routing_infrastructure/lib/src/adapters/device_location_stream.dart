import 'package:core_kernel/core_kernel.dart';
import 'package:location_service/location_service.dart';
import 'package:routing_api/routing_api.dart';

/// Answers `LocationStreamPort` from the device's own position source.
///
/// This is the adapter that turns a *fix* into a *place*. `GeoFix` carries an
/// accuracy radius and the moment the device produced it; `GeoPoint` carries
/// neither, because routing needs somewhere a courier can be sent rather than
/// a measurement with error bars.
///
/// Two decisions in that translation are the interesting part.
///
/// **A fix too vague to use is not a position.** A reading accurate to within
/// two kilometres would put a courier anywhere in the district, and the
/// deviation check downstream would report a wrong turn for somebody sitting
/// still. Below [minimumAccuracyMetres] the fix is refused rather than
/// forwarded, which is the difference between "I do not know where you are"
/// and "you are somewhere over there".
///
/// **The stream drops failures instead of carrying them.** That is the port's
/// contract, and it is not laziness: a stream that errored would tear down
/// every listener the first time a courier walked into a car park, and
/// re-subscribing after that is a concern no screen should have to code
/// around. The one-shot [current] reports failures, because a caller that
/// asked a question is entitled to an answer.
final class DeviceLocationStream implements LocationStreamPort {
  /// Creates the adapter over [source].
  const DeviceLocationStream({
    required this.source,
    this.minimumAccuracyMetres = 250,
    this.timeout = const Duration(seconds: 10),
  });

  /// The device's position source.
  final LocationSource source;

  /// The widest confidence circle this adapter will still call a position.
  ///
  /// Two hundred and fifty metres, which is roughly what a phone reports on
  /// cell-tower positioning alone. It is a *product* number: tighter and a
  /// courier indoors never gets a position at all, looser and the deviation
  /// check starts firing on noise.
  final double minimumAccuracyMetres;

  /// How long to wait for a one-shot fix.
  final Duration timeout;

  @override
  Future<Result<GeoPoint, RoutingFailure>> current() async {
    final fix = await source.currentFix(
      accuracy: FixAccuracy.balanced,
      timeout: timeout,
    );

    return switch (fix) {
      Failed(:final failure) => Failed(_translate(failure)),
      Success(value: final at) => _toPoint(at),
    };
  }

  @override
  Stream<GeoPoint> positions() => source
      .track(
        accuracy: FixAccuracy.balanced,
        // Fifty metres of movement between emissions. A shift-long
        // subscription that emitted on every sensor tick would flatten a
        // battery by lunchtime, and no routing decision changes over fifty
        // metres.
        distanceFilterMetres: 50,
      )
      // `expand` rather than `map` plus `where`: a failure becomes an empty
      // list, which drops it without a cast and without a branch that claims
      // to be unreachable.
      .expand(
        (fix) => fix
            .fold<Result<GeoPoint, RoutingFailure>>(
              _toPoint,
              (failure) => Failed(_translate(failure)),
            )
            .fold((at) => [at], (_) => const <GeoPoint>[]),
      );

  Result<GeoPoint, RoutingFailure> _toPoint(GeoFix fix) {
    if (fix.accuracyMetres > minimumAccuracyMetres) {
      return Failed(
        PositionUnavailable(
          detail:
              'the fix is accurate to ${fix.accuracyMetres.round()}m, '
              'which is wider than $minimumAccuracyMetres',
        ),
      );
    }
    return GeoPoint.at(latitude: fix.latitude, longitude: fix.longitude);
  }

  /// Turns a location failure into the vocabulary the port promises.
  ///
  /// All five collapse to `PositionUnavailable`, and the detail is what
  /// survives. That is a deliberate narrowing: `location_service` distinguishes
  /// five cases because a *permission screen* behaves differently about each
  /// one, and routing's caller has exactly one response to all of them — plan
  /// without a position. The feature that owns the permission prompt reads the
  /// five; this one does not need to.
  static RoutingFailure _translate(LocationFailure failure) =>
      switch (failure) {
        LocationServicesDisabled() => const PositionUnavailable(
          detail: 'location services are switched off',
        ),
        LocationPermissionDenied() => const PositionUnavailable(
          detail: 'location permission has not been granted',
        ),
        LocationPermissionBlocked() => const PositionUnavailable(
          detail: 'location permission is blocked in settings',
        ),
        LocationTimeout() => const PositionUnavailable(
          detail: 'no fix arrived in time',
        ),
        LocationUnavailable() => const PositionUnavailable(
          detail: 'the device could not produce a fix',
        ),
      };
}
