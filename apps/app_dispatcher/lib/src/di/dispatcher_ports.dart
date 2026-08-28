import 'package:analytics_otel/analytics_otel.dart';
import 'package:connectivity_monitor/connectivity_monitor.dart';
import 'package:core_ports/core_ports.dart';
import 'package:device_permissions/device_permissions.dart';
import 'package:http_dio/http_dio.dart';
import 'package:injectable/injectable.dart';
import 'package:secure_store/secure_store.dart';
import 'package:storage_drift/storage_drift.dart';

import 'dispatcher_platform.dart';
import 'dispatcher_runtime.dart';

/// The cross-cutting ports, answered by the real adapters.
///
/// **Almost identical to `CourierPorts`, and that is the finding.** Every port
/// in `core_ports` is a contract more than one feature needs and none owns, so
/// two apps have no reason to disagree about it — the clock is a clock at a
/// desk and in a van. Scenario 5's table lists five ports and every one of
/// them belongs to a *feature*, which is exactly where two audiences have
/// something to disagree about.
///
/// The one difference is `PermissionRequester`, and it is a difference of
/// absence: a dispatcher's desk has no camera or location to ask about.
@module
abstract class DispatcherPorts {
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
  Logger logger(DispatcherPlatform platform) => OtelLogger(platform.tracer);

  /// Analytics, into the same trace.
  @lazySingleton
  AnalyticsSink analytics(DispatcherPlatform platform) =>
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
  Future<NetworkStatus> network(DispatcherPlatform platform) async {
    final monitor = ConnectivityMonitor(platform.connectivity);
    await monitor.start();
    return monitor;
  }

  /// Asking a person for a device permission.
  ///
  /// It takes a `KeyValueStore` as well as the plugin, because "has this
  /// person already been asked" is not a question the operating system
  /// answers: iOS reports `denied` both for "never asked" and for "asked and
  /// refused", and a dispatcher who is asked again every launch turns the app
  /// off. The log is the adapter remembering.
  @lazySingleton
  PermissionRequester permissions(
    DispatcherPlatform platform,
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
  PeykDatabase database(DispatcherPlatform platform) =>
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
  SecureStore secureStore(DispatcherPlatform platform) =>
      KeychainSecureStore(platform.secureStorage, options: const {});

  /// The transport every REST adapter sends through.
  @lazySingleton
  HttpTransport transport(DispatcherPlatform platform) =>
      DioHttpTransport(platform.http);
}
