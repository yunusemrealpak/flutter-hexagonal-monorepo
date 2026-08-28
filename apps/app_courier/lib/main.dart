import 'dart:io';

import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:firebase_messaging_platform_interface/firebase_messaging_platform_interface.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:opentelemetry/api.dart' as otel;
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';

import 'src/courier_app.dart';
import 'src/di/courier_platform.dart';
import 'src/di/injection.dart';
import 'src/router/courier_routes.dart';

/// What this app's own tests build it from.
///
/// An app has no dependents, so this is not a public surface in the usual
/// sense — it is the entry point saying which of its parts can be assembled
/// separately. The tests import this file rather than reaching into `src/`,
/// which is rule S3 applying to an app exactly as it does to a package: a
/// `package:*/src/` import means one thing in this workspace, and a test
/// writing one would make it mean two.
export 'src/catalogue/courier_catalogue.dart';
export 'src/courier_app.dart';
export 'src/di/courier_platform.dart';
export 'src/di/injection.dart' show configureCourier, courierContainer;
export 'src/router/courier_routes.dart';
export 'src/router/peyk_router.dart';

/// The courier app, in production.
///
/// The only file in this app that names a plugin's singleton, and that is
/// what makes everything below it testable: every adapter takes a platform
/// interface, `CourierPlatform` gathers them, and a test builds one from
/// whatever it likes and gets the same container.
///
/// A flavour is a second file beside this one — `lib/main_staging.dart`
/// building a `CourierPlatform` against a different base URL — which is why
/// rule S1's app row permits several entry points directly under `lib/`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = await configureCourier(
    CourierPlatform(
      database: NativeDatabase.createInBackground(await _databaseFile()),
      http: Dio(BaseOptions(baseUrl: _apiBaseUrl)),
      secureStorage: FlutterSecureStoragePlatform.instance,
      connectivity: ConnectivityPlatform.instance,
      permissions: PermissionHandlerPlatform.instance,
      location: GeolocatorPlatform.instance,
      camera: ImagePickerPlatform.instance,
      push: FirebaseMessagingPlatform.instance,
      tracer: otel.globalTracerProvider.getTracer('peyk.courier'),
    ),
  );

  runApp(CourierApp(router: buildCourierRouter(container).build()));
}

/// Where the operation's API lives.
///
/// A constant here and not a `--dart-define`, because this repository has no
/// backend to point at. A flavour file is where a real one would differ, and
/// that is the shape the entry-point rule exists to permit.
const String _apiBaseUrl = 'https://api.peyk.example';

/// The device's database file.
///
/// `getApplicationDocumentsDirectory` would mean a `path_provider` dependency
/// in this app, and a directory this repository cannot create in a test. The
/// production shape is one line; what matters architecturally is that
/// `CourierPlatform` takes a `QueryExecutor` and does not care which.
Future<File> _databaseFile() async => File('peyk.sqlite');
