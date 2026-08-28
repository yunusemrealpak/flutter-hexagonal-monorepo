import 'package:core_ports/core_ports.dart';
import 'package:injectable/injectable.dart';
import 'package:payments_api/payments_api.dart';
import 'package:shipments_api/shipments_api.dart';
import 'package:shipments_application/shipments_application.dart';
import 'package:shipments_testing/shipments_testing.dart';

/// shipments, on fakes.
///
/// Scenario 1 is visible in one line of this file: `AdvanceShipment` takes a
/// `PaymentStatusReader`, which is declared in `payments_api`. It does *not*
/// take `payments_application`, and `payments_application` does not take
/// `shipments_application`. Two features that need each other, and a graph
/// with no cycle in it — because contract packages depend on no
/// implementation.
@module
abstract class HarnessShipments {
  /// The operation's shipments, in a map.
  @lazySingleton
  InMemoryShipmentGateway get fakeGateway => InMemoryShipmentGateway();

  /// The same instance, as the port.
  @lazySingleton
  ShipmentGateway gateway(InMemoryShipmentGateway fake) => fake;

  /// The offline copy, also in a map.
  @lazySingleton
  ShipmentCache get cache => InMemoryShipmentCache();

  /// A resolver that answers whatever it was told to.
  @lazySingleton
  BarcodeResolverPort get barcodes => FakeBarcodeResolver();

  /// Reading one shipment, gateway first and cache behind it.
  @lazySingleton
  FindShipment find(ShipmentGateway gateway, ShipmentCache cache) =>
      FindShipment(gateway: gateway, cache: cache);

  /// Turning a scan into a shipment.
  @lazySingleton
  ResolveBarcode resolve(BarcodeResolverPort resolver, FindShipment find) =>
      ResolveBarcode(resolver: resolver, findShipment: find);

  /// A courier's list for a day.
  @lazySingleton
  LoadManifest manifest(ShipmentGateway gateway, ShipmentCache cache) =>
      LoadManifest(gateway: gateway, cache: cache);

  /// The state machine.
  @lazySingleton
  AdvanceShipment advance(
    ShipmentGateway gateway,
    ShipmentCache cache,
    Clock clock,
    DomainEventBus events,
    Logger logger,
    PaymentStatusReader payments,
  ) => AdvanceShipment(
    gateway: gateway,
    cache: cache,
    clock: clock,
    events: events,
    logger: logger,
    payments: payments,
  );

  /// The one implementation of `ShipmentsFacade`.
  @lazySingleton
  ShipmentsFacade shipments(
    FindShipment find,
    ResolveBarcode resolve,
    LoadManifest manifest,
    AdvanceShipment advance,
  ) => ShipmentsCoordinator(
    findShipment: find,
    resolveBarcode: resolve,
    loadManifest: manifest,
    advanceShipment: advance,
  );
}
