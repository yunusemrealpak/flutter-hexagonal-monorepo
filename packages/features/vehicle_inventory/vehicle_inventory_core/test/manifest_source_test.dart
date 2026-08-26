import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:core_testing/core_testing.dart';
import 'package:http_dio/http_dio.dart';
import 'package:test/test.dart';
import 'package:vehicle_inventory_api/vehicle_inventory_api.dart';
import 'package:vehicle_inventory_core/vehicle_inventory_core.dart';

List<String> manifestOf(Result<List<String>, VehicleInventoryFailure> result) =>
    (result as Success<List<String>, VehicleInventoryFailure>).value;

void main() {
  late FakeHttpTransport http;
  late InMemoryKeyValueStore store;
  late ManifestSource cached;

  setUp(() {
    http = FakeHttpTransport();
    store = InMemoryKeyValueStore();
    cached = CachedManifestSource(
      upstream: HttpManifestSource(transport: http),
      store: store,
    );
  });

  group('the HTTP source', () {
    test('reads the identifiers the depot sent', () async {
      http.enqueueJson(['SHP-1', 'SHP-2']);

      final manifest = await HttpManifestSource(
        transport: http,
      ).manifestFor('courier-7');

      expect(manifestOf(manifest), ['SHP-1', 'SHP-2']);
    });

    test(
      'a body of the wrong shape is unavailable, not an exception',
      () async {
        http.enqueueJson({'manifest': 'nope'});

        final manifest = await HttpManifestSource(
          transport: http,
        ).manifestFor('courier-7');

        expect(
          (manifest as Failed<List<String>, VehicleInventoryFailure>).failure,
          isA<ManifestUnavailable>(),
        );
      },
    );

    test('an entry that is not a string is unavailable', () async {
      http.enqueueJson(['SHP-1', 7]);

      final manifest = await HttpManifestSource(
        transport: http,
      ).manifestFor('courier-7');

      expect(
        manifest,
        isA<Failed<List<String>, VehicleInventoryFailure>>(),
      );
    });

    test('a transport failure becomes ManifestUnavailable', () async {
      http.enqueueFailure(const TransportOffline());

      final manifest = await HttpManifestSource(
        transport: http,
      ).manifestFor('courier-7');

      expect(
        (manifest as Failed<List<String>, VehicleInventoryFailure>).failure,
        isA<ManifestUnavailable>(),
      );
    });
  });

  group('the cache in front of it', () {
    test('passes a fresh manifest through and remembers it', () async {
      http.enqueueJson(['SHP-1']);

      expect(manifestOf(await cached.manifestFor('courier-7')), ['SHP-1']);

      final stored = await store.read(
        '${CachedManifestSource.keyPrefix}courier-7',
      );
      expect((stored as Success<String?, StoreFailure>).value, isNotNull);
    });

    test('answers from the cache when the depot cannot be reached', () async {
      http.enqueueJson(['SHP-1', 'SHP-2']);
      await cached.manifestFor('courier-7');

      http.enqueueFailure(const TransportOffline());
      final offline = await cached.manifestFor('courier-7');

      expect(manifestOf(offline), ['SHP-1', 'SHP-2']);
    });

    test('reports the upstream failure when there is nothing cached', () async {
      http.enqueueFailure(const TransportOffline());

      final offline = await cached.manifestFor('courier-7');

      expect(
        (offline as Failed<List<String>, VehicleInventoryFailure>).failure,
        isA<ManifestUnavailable>(),
      );
    });

    test('a cache that cannot be written does not fail the call', () async {
      http.enqueueJson(['SHP-1']);
      store.failNextWith(const StoreOutOfSpace());

      expect(manifestOf(await cached.manifestFor('courier-7')), ['SHP-1']);
    });

    test('one courier does not read another courier cache', () async {
      http.enqueueJson(['SHP-1']);
      await cached.manifestFor('courier-7');

      http.enqueueFailure(const TransportOffline());
      final other = await cached.manifestFor('courier-9');

      expect(other, isA<Failed<List<String>, VehicleInventoryFailure>>());
    });
  });
}
