import 'package:core_kernel/core_kernel.dart';
import 'package:core_testing/core_testing.dart';
import 'package:identity_api/identity_api.dart';
import 'package:shipments_application/shipments_application.dart';
import 'package:shipments_testing/shipments_testing.dart';

/// Everything a use case in this package needs, wired to fakes.
///
/// The composition root of a test. It looks like the one in `apps/*` because
/// it is the same job: decide which adapter answers each port. The difference
/// is only which adapters, which is the whole point of the architecture — the
/// use cases below do not change between here and a device.
final class Harness {
  /// Builds the fakes and the use cases over them.
  Harness() {
    findShipment = FindShipment(gateway: gateway, cache: cache);
    advanceShipment = AdvanceShipment(
      gateway: gateway,
      cache: cache,
      clock: clock,
      events: events,
      logger: logger,
    );
    resolveBarcode = ResolveBarcode(
      resolver: resolver,
      findShipment: findShipment,
    );
    loadManifest = LoadManifest(gateway: gateway, cache: cache);
    coordinator = ShipmentsCoordinator(
      findShipment: findShipment,
      resolveBarcode: resolveBarcode,
      loadManifest: loadManifest,
      advanceShipment: advanceShipment,
    );
  }

  /// The instant `clock` reports, so assertions can name it.
  static final DateTime now = DateTime.utc(2026, 3, 14, 12);

  /// The gateway fake.
  final InMemoryShipmentGateway gateway = InMemoryShipmentGateway();

  /// The cache fake.
  final InMemoryShipmentCache cache = InMemoryShipmentCache();

  /// The barcode resolver fake.
  final FakeBarcodeResolver resolver = FakeBarcodeResolver();

  /// A clock that does not move, so nothing in the suite waits.
  final FakeClock clock = FakeClock(now);

  /// A bus that records what was published.
  final RecordingEventBus events = RecordingEventBus();

  /// A logger that records instead of printing.
  final RecordingLogger logger = RecordingLogger();

  /// The use cases, built over the fakes above.
  late final FindShipment findShipment;

  /// See [findShipment].
  late final AdvanceShipment advanceShipment;

  /// See [findShipment].
  late final ResolveBarcode resolveBarcode;

  /// See [findShipment].
  late final LoadManifest loadManifest;

  /// The driving port, over all four use cases.
  late final ShipmentsCoordinator coordinator;

  /// A courier identifier.
  static ActorId courier([String raw = 'courier-1']) =>
      ActorId.parse(raw).fold((id) => id, (f) => throw StateError('$f'));

  /// Unwraps a result in test setup.
  static T unwrap<T, F>(Result<T, F> result) =>
      result.fold((value) => value, (f) => throw StateError('$f'));
}
