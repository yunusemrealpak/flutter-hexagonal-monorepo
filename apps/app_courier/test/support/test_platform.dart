import 'package:app_courier/main.dart';
import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:firebase_messaging_platform_interface/firebase_messaging_platform_interface.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:opentelemetry/api.dart' as otel;
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart'
    as handler;
import 'package:workmanager_platform_interface/workmanager_platform_interface.dart';

/// The device, as a test can supply it.
///
/// **This function is the payoff of a decision made in phase 2.** Every
/// adapter in `platform/*` takes a plugin's *platform interface* through its
/// constructor rather than reaching for the plugin's singleton, so the whole
/// of this app — the same adapters, the same use cases, the same screens —
/// stands up in a test with no device, no Firebase project and no keychain.
///
/// The database is in memory and the rest are stubs. Nothing here is a fake of
/// a *product* concept: every port a feature declares is answered by its real
/// adapter, and this is only the layer underneath.
CourierPlatform testPlatform() => CourierPlatform(
  database: NativeDatabase.memory(),
  http: Dio(),
  secureStorage: _SecureStorage(),
  connectivity: _Connectivity(),
  permissions: _Permissions(),
  location: _Location(),
  camera: _Camera(),
  push: _Push(),
  scheduler: _Scheduler(),
  tracer: otel.globalTracerProvider.getTracer('peyk.courier.test'),
);

final class _SecureStorage extends FlutterSecureStoragePlatform {
  final Map<String, String> _entries = {};

  @override
  Future<bool> containsKey({
    required String key,
    required Map<String, String> options,
  }) async => _entries.containsKey(key);

  @override
  Future<void> delete({
    required String key,
    required Map<String, String> options,
  }) async => _entries.remove(key);

  @override
  Future<void> deleteAll({required Map<String, String> options}) async =>
      _entries.clear();

  @override
  Future<String?> read({
    required String key,
    required Map<String, String> options,
  }) async => _entries[key];

  @override
  Future<Map<String, String>> readAll({
    required Map<String, String> options,
  }) async => Map.of(_entries);

  @override
  Future<void> write({
    required String key,
    required String value,
    required Map<String, String> options,
  }) async => _entries[key] = value;
}

final class _Connectivity extends ConnectivityPlatform {
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => const [
    ConnectivityResult.wifi,
  ];

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      const Stream.empty();
}

final class _Permissions extends handler.PermissionHandlerPlatform {
  @override
  Future<Map<handler.Permission, handler.PermissionStatus>> requestPermissions(
    List<handler.Permission> permissions,
  ) async => {
    for (final it in permissions) it: handler.PermissionStatus.granted,
  };

  @override
  Future<handler.PermissionStatus> checkPermissionStatus(
    handler.Permission permission,
  ) async => handler.PermissionStatus.granted;

  @override
  Future<handler.ServiceStatus> checkServiceStatus(
    handler.Permission permission,
  ) async => handler.ServiceStatus.enabled;

  @override
  Future<bool> shouldShowRequestPermissionRationale(
    handler.Permission permission,
  ) async => false;

  @override
  Future<bool> openAppSettings() async => true;
}

final class _Location extends GeolocatorPlatform {
  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.always;

  @override
  Future<LocationPermission> requestPermission() async =>
      LocationPermission.always;

  @override
  Future<bool> isLocationServiceEnabled() async => true;
}

final class _Camera extends ImagePickerPlatform {}

final class _Push extends FirebaseMessagingPlatform {}

/// A scheduler that accepts everything and remembers nothing.
///
/// The default `WorkmanagerPlatform` throws `UnimplementedError` from every
/// method, so an app that schedules on start-up would fail every test that
/// builds it. Accepting silently is what "there is no operating system here"
/// looks like; a test that cares what was scheduled substitutes a
/// `FakeBackgroundScheduler` for the port instead.
final class _Scheduler extends WorkmanagerPlatform {
  _Scheduler() : super();

  @override
  Future<void> registerPeriodicTask(
    String uniqueName,
    String taskName, {
    Duration? frequency,
    Duration? flexInterval,
    Map<String, dynamic>? inputData,
    Duration? initialDelay,
    Constraints? constraints,
    ExistingPeriodicWorkPolicy? existingWorkPolicy,
    BackoffPolicy? backoffPolicy,
    Duration? backoffPolicyDelay,
    String? tag,
    ForegroundServiceConfig? foregroundServiceConfig,
  }) async {}

  @override
  Future<void> cancelByUniqueName(String uniqueName) async {}

  @override
  Future<void> cancelAll() async {}
}
