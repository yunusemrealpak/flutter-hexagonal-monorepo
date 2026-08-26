import 'package:core_kernel/core_kernel.dart';
import 'package:core_testing/core_testing.dart';
import 'package:http_dio/http_dio.dart';
import 'package:identity_api/identity_api.dart';
import 'package:shipments_api/shipments_api.dart';
import 'package:vehicle_inventory_api/vehicle_inventory_api.dart';
import 'package:vehicle_inventory_core/vehicle_inventory_core.dart';

/// Everything a vehicle inventory test needs, wired the way an app would.
///
/// The manifest source is the *composed* one — cached over HTTP — because that
/// is what an app builds and because the interesting behaviour is what happens
/// when the network is not there. Two fakes, both from the packages that own
/// the contracts they stand in for.
final class InventoryHarness {
  InventoryHarness() {
    final store = KeyValueLoadCountStore(store: keyValue);
    manifests = CachedManifestSource(
      upstream: HttpManifestSource(transport: http),
      store: keyValue,
    );
    facade = VehicleInventoryCoordinator(
      start: StartCount(
        manifests: manifests,
        store: store,
        clock: clock,
        ids: ids,
      ),
      record: RecordScan(store: store),
      close: CloseCount(store: store, clock: clock, logger: logger),
      find: FindOpenCount(store: store),
    );
  }

  /// The store behind the counts and the manifest cache.
  final InMemoryKeyValueStore keyValue = InMemoryKeyValueStore();

  /// The depot's backend.
  final FakeHttpTransport http = FakeHttpTransport();

  /// Time, under the test's control.
  final FakeClock clock = FakeClock(DateTime.utc(2026, 3, 4, 6, 30));

  /// Identifiers, under the test's control.
  final FakeIdGenerator ids = FakeIdGenerator('CNT');

  /// Where the discrepancy warning is looked for.
  final RecordingLogger logger = RecordingLogger();

  /// The composed manifest source.
  late final ManifestSource manifests;

  /// The facade under test.
  late final VehicleInventoryCoordinator facade;

  /// The courier every test counts for.
  static final ActorId courier =
      (ActorId.parse('courier-7') as Success<ActorId, IdentityFailure>).value;

  /// Reads a shipment identifier, throwing on an invalid fixture.
  static ShipmentId parcel(String raw) =>
      (ShipmentId.parse(raw) as Success<ShipmentId, ShipmentFailure>).value;

  /// Queues the manifest the depot will answer with.
  void depotSays(List<String> identifiers) => http.enqueueJson(identifiers);

  /// The count behind a successful result.
  static LoadCount valueOf(Result<LoadCount, VehicleInventoryFailure> result) =>
      (result as Success<LoadCount, VehicleInventoryFailure>).value;

  /// The failure behind an unsuccessful one.
  static VehicleInventoryFailure failureOf(
    Result<LoadCount, VehicleInventoryFailure> result,
  ) => (result as Failed<LoadCount, VehicleInventoryFailure>).failure;
}
