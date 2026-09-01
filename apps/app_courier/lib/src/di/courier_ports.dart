import 'package:analytics_otel/analytics_otel.dart';
import 'package:connectivity_monitor/connectivity_monitor.dart';
import 'package:core_ports/core_ports.dart';
import 'package:device_permissions/device_permissions.dart';
import 'package:http_dio/http_dio.dart';
import 'package:injectable/injectable.dart';
import 'package:secure_store/secure_store.dart';
import 'package:storage_drift/storage_drift.dart';

import 'courier_platform.dart';
import 'courier_runtime.dart';

/// The cross-cutting ports, answered by the real adapters.
///
/// Every one of these is the same *port* `app_harness` answers with a fake.
/// The use cases below them are the same packages, unchanged and unaware —
/// which is the claim scenario 5 makes and this file is one half of the proof.
@module
abstract class CourierPorts {
  /// The device's clock.
  ///
  /// A one-line adapter declared in this app rather than in `core_ports`,
  /// because `DateTime.now()` is the one thing rule A1 forbids everywhere
  /// *except* here. A composition root is where ambient state is allowed to
  /// enter, and confining it to a class this small is what makes that true
  /// rather than aspirational.
  @lazySingleton
  Clock get clock => const SystemClock();

  /// Identifiers from the platform's random source.
  @lazySingleton
  IdGenerator get ids => const UuidGenerator(PlatformRandom());

  /// The platform's random source.
  @lazySingleton
  RandomSource get random => const PlatformRandom();

  /// Logs, into the trace.
  @lazySingleton
  Logger logger(CourierPlatform platform) => OtelLogger(platform.tracer);

  /// Analytics, into the same trace.
  @lazySingleton
  AnalyticsSink analytics(CourierPlatform platform) =>
      OtelAnalyticsSink(platform.tracer);

  /// The event bus.
  ///
  /// In-process, and there is no other kind: a domain event is a fact one
  /// feature states and another hears, inside one app. An event bus that
  /// crossed a process boundary would be a message queue, and the product has
  /// one of those — it is called `sync`.
  @lazySingleton
  DomainEventBus get events => BroadcastEventBus();

  /// Whether there is a network.
  @lazySingleton
  @preResolve
  Future<NetworkStatus> network(CourierPlatform platform) async {
    final monitor = ConnectivityMonitor(platform.connectivity);
    await monitor.start();
    return monitor;
  }

  /// Asking a person for a device permission.
  ///
  /// It takes a `KeyValueStore` as well as the plugin, because "has this
  /// person already been asked" is not a question the operating system
  /// answers: iOS reports `denied` both for "never asked" and for "asked and
  /// refused", and a courier who is asked again every launch turns the app
  /// off. The log is the adapter remembering.
  @lazySingleton
  PermissionRequester permissions(
    CourierPlatform platform,
    KeyValueStore askLog,
  ) => DevicePermissionRequester(platform.permissions, askLog);

  /// Feature flags.
  ///
  /// Hard-coded rather than fetched. A flag service is a remote dependency the
  /// product does not have, and inventing one here would put an adapter in an
  /// app — which is the one place §2 permits it and the last place it belongs.
  @lazySingleton
  FeatureFlagReader get flags => const NoFeatureFlags();

  /// The device's database.
  @lazySingleton
  PeykDatabase database(CourierPlatform platform) =>
      PeykDatabase(platform.database);

  /// The key-value table.
  @lazySingleton
  KeyValueStore keyValues(PeykDatabase database, Clock clock) =>
      DriftKeyValueStore(database.keyValueDao, clock);

  /// The keychain.
  ///
  /// Scenario 5 does not list `SecureStore`, and that is worth noticing: it is
  /// a `core_ports` contract rather than a feature's, so every app that binds
  /// a real one binds the same adapter. The rows in that table are the ports a
  /// *feature* declares, which is exactly where two apps have reason to
  /// disagree.
  @lazySingleton
  SecureStore secureStore(CourierPlatform platform) => KeychainSecureStore(
    platform.secureStorage,
    // Named rather than assembled here, and not a default: see
    // `KeychainOptions`. What stood here was `const {}`, which states no
    // accessibility class and no backup behaviour and leaves both to
    // whatever the native side happens to pick.
    options: KeychainOptions.deviceBound,
  );

  /// The transport every REST adapter sends through.
  @lazySingleton
  HttpTransport transport(CourierPlatform platform) =>
      DioHttpTransport(platform.http);
}
