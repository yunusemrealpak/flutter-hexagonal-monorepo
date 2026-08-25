/// Fakes, fixtures and contract kits for shipments.
///
/// Three things, and the third is the one that matters most:
///
/// **Fakes.** `InMemoryShipmentGateway`, `InMemoryShipmentCache` and
/// `FakeBarcodeResolver`. Behavioural, not scripted: they really store, really
/// resolve, and can be told to fail, because failure is part of a port's
/// contract and a fake that could not produce it would leave every caller's
/// failure branch untested.
///
/// **A builder.** `ShipmentBuilder` reaches a state by *walking the state
/// machine to it*, so a fixture can never be a shipment the machine cannot
/// actually produce. A test asserting against such a fixture is asserting
/// about a situation that never happens.
///
/// **Contract kits.** `runShipmentGatewayContract` and
/// `runShipmentCacheContract` are one suite each, run against every
/// implementation of the port — the fakes here and the adapters in
/// `shipments_infrastructure`. This is what structurally prevents a fake and
/// the real adapter from drifting apart: without it, nothing checks that "what
/// the fake does" is still "what the real one does", and the tests that
/// trusted the fake go on passing while production breaks.
///
/// `test` is a runtime dependency of this package rather than a dev
/// dependency, because a contract kit *is* tests — it calls `group` and `test`
/// from `lib/`. `core_testing` keeps `test` in dev dependencies because it
/// ships only fakes.
library;

export 'src/fake_barcode_resolver.dart';
export 'src/in_memory_shipment_cache.dart';
export 'src/in_memory_shipment_gateway.dart';
export 'src/shipment_builder.dart';
export 'src/shipment_cache_contract.dart';
export 'src/shipment_gateway_contract.dart';
