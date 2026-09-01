import 'dart:async';
import 'dart:io';

import 'package:analytics_otel/analytics_otel.dart';
import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:core_ports/core_ports.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:firebase_messaging_platform_interface/firebase_messaging_platform_interface.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:http_dio/http_dio.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:opentelemetry/api.dart' as otel;
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';
import 'package:push_messaging/push_messaging.dart';
import 'package:sync_api/sync_api.dart';

import 'src/courier_app.dart';
import 'src/di/courier_platform.dart';
import 'src/di/courier_runtime.dart';
import 'src/di/injection.dart';
import 'src/push/push_entry.dart';
import 'src/router/courier_routes.dart';
import 'src/sync/sync_orchestrator.dart';

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
export 'src/push/courier_entry_points.dart';
export 'src/push/push_entry.dart';
export 'src/router/courier_flow.dart';
export 'src/router/courier_routes.dart';
export 'src/router/peyk_router.dart';
export 'src/router/session_refresh.dart';
export 'src/shell/courier_shell.dart';
export 'src/shell/courier_tabs.dart';
export 'src/sync/sync_orchestrator.dart';

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

  // Telemetry first, and the order is enforced by the library rather than by
  // convention: `registerGlobalTracerProvider` throws once anything has read
  // `globalTracerProvider`, and the line below this block reads it. Until this
  // call existed the getter answered a no-op provider, so every span and every
  // log line this application produced was discarded inside OpenTelemetry with
  // nothing failing to say so.
  PeykTelemetry.install(
    exporter: PeykTelemetry.collectorAt(Uri.parse(_collectorEndpoint)),
    serviceName: 'peyk.courier',
    clock: const SystemClock(),
  );

  final platform = CourierPlatform(
    database: NativeDatabase.createInBackground(await _databaseFile()),
    http: Dio(PeykTransport.optionsFor(_apiBaseUrl)),
    secureStorage: FlutterSecureStoragePlatform.instance,
    connectivity: ConnectivityPlatform.instance,
    permissions: PermissionHandlerPlatform.instance,
    location: GeolocatorPlatform.instance,
    camera: ImagePickerPlatform.instance,
    push: FirebaseMessagingPlatform.instance,
    tracer: otel.globalTracerProvider.getTracer('peyk.courier'),
  );

  final container = await configureCourier(platform);

  // The interceptor chain, installed once the container can answer what it
  // needs and the client exists for the authorising one to replay through.
  // Two steps rather than one because of that order, and it is the composition
  // root's job for the same reason the base URL is: a cross-cutting policy
  // that a gateway could opt out of is a policy in name only.
  PeykTransport.installOn(
    platform.http,
    authorization: container<AuthorizationProvider>(),
    logger: container<Logger>(),
    ids: container<IdGenerator>(),
    clock: container<Clock>(),
    random: container<RandomSource>(),
  );

  // Nothing enqueues through this and nothing waits for it: it decides when
  // a queue that already holds the work is worth attempting. Started before
  // the first frame so that an app reopened on the street sends what was
  // written in a basement.
  SyncOrchestrator(
    sync: container<SyncFacade>(),
    network: container<NetworkStatus>(),
    logger: container<Logger>(),
  ).start();

  final router = buildCourierRouter(container).build();

  // Arrival from a pressed notification, which is the one entry a callback
  // cannot serve — see §2.4 of docs/DEPENDENCY_RULES.md. Started before the
  // first frame and deliberately not awaited: a launch message that resolves
  // first sets the location before anything is drawn, so a cold start from a
  // notification does not flash the manifest on the way to the thread. It
  // goes through the router, so it goes through the guard.
  unawaited(
    PushEntry(
      push: container<PushMessagingClient>(),
      logger: container<Logger>(),
      go: (step) => router.goNamed(step.route, pathParameters: step.parameters),
    ).start(),
  );

  runApp(CourierApp(router: router));
}

/// Where the operation's API lives.
///
/// A constant here and not a `--dart-define`, because this repository has no
/// backend to point at. A flavour file is where a real one would differ, and
/// that is the shape the entry-point rule exists to permit.
const String _apiBaseUrl = 'https://api.peyk.example';

/// Where traces and product events are collected.
///
/// A constant here for the same reason [_apiBaseUrl] is one, and subject to
/// the same caveat: this repository has no collector to point at, so nothing
/// arrives. The exporter batches and retries on a timer, so an unreachable
/// endpoint costs a periodic failed request rather than anything a courier
/// notices. A flavour file is where a real one would differ.
const String _collectorEndpoint = 'https://otel.peyk.example/v1/traces';

/// The device's database file.
///
/// `getApplicationDocumentsDirectory` would mean a `path_provider` dependency
/// in this app, and a directory this repository cannot create in a test. The
/// production shape is one line; what matters architecturally is that
/// `CourierPlatform` takes a `QueryExecutor` and does not care which.
Future<File> _databaseFile() async => File('peyk.sqlite');
