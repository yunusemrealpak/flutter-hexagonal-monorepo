import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:firebase_messaging_platform_interface/firebase_messaging_platform_interface.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:opentelemetry/api.dart' as otel;
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';

/// Everything this app needs from a device, gathered into one object.
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
/// a courier's screen knows the difference.
///
/// The alternative — adapters that reach for `FirebaseMessaging.instance` —
/// would make this app's container untestable and would have made every
/// `platform/*` package untestable first.
final class CourierPlatform {
  /// Gathers the device-backed leaves.
  const CourierPlatform({
    required this.database,
    required this.http,
    required this.secureStorage,
    required this.connectivity,
    required this.permissions,
    required this.location,
    required this.camera,
    required this.push,
    required this.tracer,
  });

  /// Where SQLite lives. `NativeDatabase` on a phone, memory in a test.
  final QueryExecutor database;

  /// The HTTP client every REST adapter sends through.
  final Dio http;

  /// The keychain or keystore.
  final FlutterSecureStoragePlatform secureStorage;

  /// What reports whether there is a network.
  final ConnectivityPlatform connectivity;

  /// What asks a person for a device permission.
  final PermissionHandlerPlatform permissions;

  /// What produces a position fix.
  final GeolocatorPlatform location;

  /// What takes a photograph.
  final ImagePickerPlatform camera;

  /// What delivers a push message.
  final FirebaseMessagingPlatform push;

  /// Where spans and logs go.
  final otel.Tracer tracer;
}
