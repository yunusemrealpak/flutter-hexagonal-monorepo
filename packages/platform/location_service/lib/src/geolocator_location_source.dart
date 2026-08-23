import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart'
    as geo;
import 'fix_accuracy.dart';
import 'geo_fix.dart';
import 'location_failure.dart';
import 'location_source.dart';

/// The [LocationSource] the shipped applications run on.
///
/// ## It asks for permission through the port, not through the plugin
///
/// `geolocator` has its own permission API. This adapter ignores it and takes
/// a [PermissionRequester] through its constructor instead. Two reasons, and
/// the second is the architectural one:
///
/// - One mechanism. An app that asks for location through geolocator and for
///   the camera through permission_handler has two places where "have we
///   asked yet?" is answered, and they disagree the first time somebody
///   changes one.
/// - No `platform/*` -> `platform/*` edge. The real permission adapter lives
///   in `device_permissions`; this package depends only on the *port*, which
///   the composition root satisfies. The constitution forbids that edge, and
///   this is what obeying it looks like in practice.
///
/// ## Order of checks
///
/// Services first, then permission, then the fix. A device with location
/// switched off will refuse regardless of what the user granted, so asking for
/// permission first produces a prompt that cannot help — and spends the one
/// chance to ask on iOS.
final class GeolocatorLocationSource implements LocationSource {
  /// Reads positions through the given platform implementation, asking the
  /// given requester for access.
  const GeolocatorLocationSource(this._platform, this._permissions);

  final geo.GeolocatorPlatform _platform;
  final PermissionRequester _permissions;

  @override
  Future<Result<GeoFix, LocationFailure>> currentFix({
    FixAccuracy accuracy = FixAccuracy.balanced,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final blocked = await _blockedBy(inBackground: false);
    if (blocked != null) {
      return Failed(blocked);
    }
    try {
      final position = await _platform.getCurrentPosition(
        locationSettings: geo.LocationSettings(
          accuracy: _toPlatformAccuracy(accuracy),
          timeLimit: timeout,
        ),
      );
      return Success(_toGeoFix(position));
    } on TimeoutException {
      return Failed(LocationTimeout(timeout));
    } on Object catch (error) {
      return Failed(LocationUnavailable(detail: error.toString()));
    }
  }

  @override
  Stream<Result<GeoFix, LocationFailure>> track({
    FixAccuracy accuracy = FixAccuracy.balanced,
    int distanceFilterMetres = 25,
    bool inBackground = false,
  }) async* {
    final blocked = await _blockedBy(inBackground: inBackground);
    if (blocked != null) {
      yield Failed(blocked);
      return;
    }
    final positions = _platform.getPositionStream(
      locationSettings: geo.LocationSettings(
        accuracy: _toPlatformAccuracy(accuracy),
        distanceFilter: distanceFilterMetres,
      ),
    );
    // Failures are yielded rather than thrown, and the stream stays open after
    // one. A courier who walks into a car park loses signal and gets it back;
    // a stream that ended on the first failure would leave the shift untracked
    // from that moment on.
    yield* positions
        .map<Result<GeoFix, LocationFailure>>(
          (position) => Success(_toGeoFix(position)),
        )
        .transform(_failuresAsValues);
  }

  /// Turns an error on the platform stream into a value on ours, leaving the
  /// stream open. `fromHandlers` forwards data and completion untouched; only
  /// the error path is rewritten.
  static final _failuresAsValues =
      StreamTransformer<
        Result<GeoFix, LocationFailure>,
        Result<GeoFix, LocationFailure>
      >.fromHandlers(
        handleError: (error, stackTrace, sink) =>
            sink.add(Failed(LocationUnavailable(detail: error.toString()))),
      );

  /// The failure that stops a fix from being possible, or `null` when nothing
  /// does.
  Future<LocationFailure?> _blockedBy({required bool inBackground}) async {
    if (!await _servicesEnabled()) {
      return const LocationServicesDisabled();
    }
    final permission = inBackground
        ? DevicePermission.locationAlways
        : DevicePermission.locationWhenInUse;
    var state = await _permissions.status(permission);
    if (state == PermissionState.notDetermined) {
      state = await _permissions.request(permission);
    }
    return switch (state) {
      PermissionState.granted => null,
      PermissionState.denied ||
      PermissionState.notDetermined => const LocationPermissionDenied(),
      PermissionState.permanentlyDenied ||
      PermissionState.restricted => const LocationPermissionBlocked(),
    };
  }

  Future<bool> _servicesEnabled() async {
    try {
      return await _platform.isLocationServiceEnabled();
    } on Object {
      // A subsystem that cannot say whether it is on is treated as off, which
      // sends the caller to the one screen that could fix it.
      return false;
    }
  }

  GeoFix _toGeoFix(geo.Position position) => GeoFix(
    latitude: position.latitude,
    longitude: position.longitude,
    accuracyMetres: position.accuracy,
    // The device's own fix time, converted to UTC. Not the moment this code
    // ran: a fix taken in a basement twenty minutes ago and delivered when
    // signal returns has to stay recognisable as stale.
    capturedAt: position.timestamp.toUtc(),
  );

  geo.LocationAccuracy _toPlatformAccuracy(FixAccuracy accuracy) =>
      switch (accuracy) {
        FixAccuracy.coarse => geo.LocationAccuracy.low,
        FixAccuracy.balanced => geo.LocationAccuracy.medium,
        FixAccuracy.fine => geo.LocationAccuracy.best,
      };
}
