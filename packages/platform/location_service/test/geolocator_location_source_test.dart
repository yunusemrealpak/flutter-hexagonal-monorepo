@Tags(['unit'])
library;

import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:core_testing/core_testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart'
    as geo;
import 'package:location_service/location_service.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

geo.Position _position({
  double latitude = 41.0082,
  double longitude = 28.9784,
  double accuracy = 12,
  DateTime? timestamp,
}) => geo.Position(
  latitude: latitude,
  longitude: longitude,
  timestamp: timestamp ?? DateTime.utc(2026, 1, 1, 9),
  accuracy: accuracy,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

/// A geolocator platform the test drives directly.
final class FakeGeolocatorPlatform extends geo.GeolocatorPlatform
    with MockPlatformInterfaceMixin {
  bool servicesEnabled = true;
  Object? throwOnServiceCheck;
  Object? throwOnCurrentPosition;
  geo.Position? nextPosition;
  geo.LocationSettings? lastSettings;

  final StreamController<geo.Position> positions =
      StreamController<geo.Position>.broadcast();

  @override
  Future<bool> isLocationServiceEnabled() async {
    final error = throwOnServiceCheck;
    if (error != null) {
      // Typed as Object so a test can reproduce anything a platform channel is
      // capable of throwing.
      // ignore: only_throw_errors
      throw error;
    }
    return servicesEnabled;
  }

  @override
  Future<geo.Position> getCurrentPosition({
    geo.LocationSettings? locationSettings,
  }) async {
    lastSettings = locationSettings;
    final error = throwOnCurrentPosition;
    if (error != null) {
      // Same reason as above: the fake has to be able to reproduce whatever a
      // platform channel throws.
      // ignore: only_throw_errors
      throw error;
    }
    return nextPosition ?? _position();
  }

  @override
  Stream<geo.Position> getPositionStream({
    geo.LocationSettings? locationSettings,
  }) {
    lastSettings = locationSettings;
    return positions.stream;
  }
}

void main() {
  late FakeGeolocatorPlatform platform;
  late FakePermissionRequester permissions;
  late GeolocatorLocationSource source;

  setUp(() {
    platform = FakeGeolocatorPlatform();
    permissions = FakePermissionRequester({
      DevicePermission.locationWhenInUse: PermissionState.granted,
      DevicePermission.locationAlways: PermissionState.granted,
    });
    source = GeolocatorLocationSource(platform, permissions);
  });

  tearDown(() async => platform.positions.close());

  group('currentFix', () {
    test('maps a position onto a GeoFix', () async {
      platform.nextPosition = _position(accuracy: 8);

      final result = await source.currentFix();

      final fix = (result as Success<GeoFix, LocationFailure>).value;
      expect(fix.latitude, 41.0082);
      expect(fix.longitude, 28.9784);
      expect(fix.accuracyMetres, 8);
    });

    test("keeps the device's own fix time, in UTC", () async {
      platform.nextPosition = _position(
        timestamp: DateTime.utc(2026, 1, 1, 8, 40),
      );

      final result = await source.currentFix();

      // Not the moment this code ran: a fix taken in a basement and delivered
      // when signal returns has to stay recognisable as stale.
      expect(
        (result as Success<GeoFix, LocationFailure>).value.capturedAt,
        DateTime.utc(2026, 1, 1, 8, 40),
      );
    });

    test('checks services before permission', () async {
      platform.servicesEnabled = false;
      permissions.setState(
        DevicePermission.locationWhenInUse,
        PermissionState.denied,
      );

      final result = await source.currentFix();

      // A device with location switched off refuses regardless of the grant,
      // so prompting first spends the one chance to ask on iOS for nothing.
      expect(
        (result as Failed<GeoFix, LocationFailure>).failure,
        isA<LocationServicesDisabled>(),
      );
      expect(permissions.requested, isEmpty);
    });

    test('treats a subsystem that cannot answer as switched off', () async {
      platform.throwOnServiceCheck = StateError('no location subsystem');

      final result = await source.currentFix();

      expect(
        (result as Failed<GeoFix, LocationFailure>).failure,
        isA<LocationServicesDisabled>(),
      );
    });

    test('prompts when the permission has never been asked for', () async {
      // Nothing set: the fake reports notDetermined, and grants on request —
      // which is exactly what a first-run device does.
      source = GeolocatorLocationSource(
        platform,
        permissions = FakePermissionRequester(),
      );

      final result = await source.currentFix();

      expect(permissions.requested, [DevicePermission.locationWhenInUse]);
      expect(result.isSuccess, isTrue);
    });

    test('reports a refusal that can still be asked again', () async {
      permissions.setState(
        DevicePermission.locationWhenInUse,
        PermissionState.denied,
      );

      final result = await source.currentFix();

      expect(
        (result as Failed<GeoFix, LocationFailure>).failure,
        isA<LocationPermissionDenied>(),
      );
    });

    test('reports a refusal that cannot, as its own case', () async {
      permissions.setState(
        DevicePermission.locationWhenInUse,
        PermissionState.permanentlyDenied,
      );

      final result = await source.currentFix();

      // The only remaining route is the system settings screen. Prompting
      // again shows nothing at all on iOS, so an app that could not tell these
      // apart would offer a button that does nothing.
      expect(
        (result as Failed<GeoFix, LocationFailure>).failure,
        isA<LocationPermissionBlocked>(),
      );
    });

    test(
      'reports a timeout as its own case, carrying how long it waited',
      () async {
        platform.throwOnCurrentPosition = TimeoutException('no fix');

        final result = await source.currentFix(
          timeout: const Duration(seconds: 3),
        );

        final failure = (result as Failed<GeoFix, LocationFailure>).failure;
        expect(failure, isA<LocationTimeout>());
        expect((failure as LocationTimeout).waited, const Duration(seconds: 3));
      },
    );

    test('lets no exception escape', () async {
      platform.throwOnCurrentPosition = StateError('something unexpected');

      expect((await source.currentFix()).isFailure, isTrue);
    });

    test('passes the requested accuracy through to the platform', () async {
      await source.currentFix(accuracy: FixAccuracy.fine);

      expect(platform.lastSettings?.accuracy, geo.LocationAccuracy.best);
    });
  });

  group('track', () {
    test(
      'asks for the background grant only when tracking in background',
      () async {
        source = GeolocatorLocationSource(
          platform,
          permissions = FakePermissionRequester(),
        );

        final tracked = source.track(inBackground: true);
        final subscription = tracked.listen((_) {});
        addTearDown(subscription.cancel);
        await pumpEventQueue();

        expect(permissions.requested, [DevicePermission.locationAlways]);
      },
    );

    test('emits a failure and stops when access is refused', () async {
      permissions.setState(
        DevicePermission.locationWhenInUse,
        PermissionState.denied,
      );

      final results = await source.track().toList();

      expect(results, hasLength(1));
      expect(
        (results.single as Failed<GeoFix, LocationFailure>).failure,
        isA<LocationPermissionDenied>(),
      );
    });

    test('keeps emitting after a failure', () async {
      final seen = <Result<GeoFix, LocationFailure>>[];
      final subscription = source.track().listen(seen.add);
      addTearDown(subscription.cancel);
      await pumpEventQueue();

      platform.positions.addError(StateError('signal lost'));
      await pumpEventQueue();
      platform.positions.add(_position());
      await pumpEventQueue();

      // A courier who walks into a car park loses signal and gets it back. A
      // stream that ended on the first failure would leave the rest of the
      // shift untracked.
      expect(seen, hasLength(2));
      expect(seen.first.isFailure, isTrue);
      expect(seen.last.isSuccess, isTrue);
    });

    test('passes the distance filter through', () async {
      final subscription = source
          .track(distanceFilterMetres: 100)
          .listen((_) {});
      addTearDown(subscription.cancel);
      await pumpEventQueue();

      expect(platform.lastSettings?.distanceFilter, 100);
    });
  });
}
