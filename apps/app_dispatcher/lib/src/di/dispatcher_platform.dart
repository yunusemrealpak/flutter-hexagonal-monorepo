import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:opentelemetry/api.dart' as otel;
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';

/// Everything this app needs from a device, gathered into one object.
///
/// **Six, where `CourierPlatform` has eight.** There is no camera and no push
/// client: nothing on a dispatcher's screen photographs a parcel, and an alert
/// at a desk is a row on the board rather than a notification. Those two
/// plugins are not dependencies of this app, so they are not compiled into it.
///
/// The GPS is here and should not be, and the README says why in one section
/// rather than being quiet about it.
///
/// **This is the composition root taking its own dependencies**, and it is
/// here for a reason worth stating: every adapter in `platform/*` already
/// takes a plugin's *platform interface* through its constructor rather than
/// reaching for the plugin's singleton. That was a decision made in phase 2 so
/// that an adapter could be tested without a device — and this class is what
/// that decision buys at the top of the tree.
///
/// `main.dart` builds one from the real plugin instances. A test builds one
/// from whatever it wants and gets the *same* container, with the same
/// adapters, the same use cases and the same screens. Nothing between here and
/// a dispatcher's screen knows the difference.
///
/// The alternative — adapters that reach for `FirebaseMessaging.instance` —
/// would make this app's container untestable and would have made every
/// `platform/*` package untestable first.
final class DispatcherPlatform {
  /// Gathers the device-backed leaves.
  const DispatcherPlatform({
    required this.database,
    required this.http,
    required this.secureStorage,
    required this.location,
    required this.connectivity,
    required this.permissions,
    required this.tracer,
  });

  /// Where SQLite lives. `NativeDatabase` on a phone, memory in a test.
  final QueryExecutor database;

  /// The HTTP client every REST adapter sends through.
  final Dio http;

  /// The keychain or keystore.
  final FlutterSecureStoragePlatform secureStorage;

  /// What produces a position fix.
  ///
  /// Here for a reason worth reading before copying: two ports this app
  /// composes take one, and neither can be honestly answered from a desk. See
  /// the README.
  final GeolocatorPlatform location;

  /// What reports whether there is a network.
  final ConnectivityPlatform connectivity;

  /// What asks a person for a device permission.
  final PermissionHandlerPlatform permissions;

  /// Where spans and logs go.
  final otel.Tracer tracer;
}
