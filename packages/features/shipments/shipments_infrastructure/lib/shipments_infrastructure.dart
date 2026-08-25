/// The shipments adapters: what answers its driven ports, the DTOs that cross
/// the wire, and the mappers between them.
///
/// This is the only package in the feature that knows shipments travel as
/// JSON over HTTP. `shipments_application` may not depend on it — section 2
/// forbids the edge outright — so a use case can never see an `HttpRequest`
/// and can never end up owning a retry policy.
///
/// | Type | Answers |
/// |---|---|
/// | `RestShipmentGateway` | `ShipmentGateway`, over `HttpTransport` |
/// | `KeyValueShipmentCache` | `ShipmentCache`, over `KeyValueStore` |
/// | `RemoteBarcodeResolver` | `BarcodeResolverPort`, by asking the operation |
/// | `ManifestBarcodeResolver` | `BarcodeResolverPort`, from the device |
///
/// The last two are one port with two adapters, chosen by an app's composition
/// root — the small version of scenario 4. A scan on a desk should hit the
/// source of truth; a scan in a warehouse doorway with no signal should still
/// work.
///
/// `ShipmentMapper` is where invariant 1.2.10 is enforced. Nothing above it
/// sees a DTO and nothing below it sees an entity, and it is hand-written
/// because deciding that an absent `barcode` is `MalformedBarcode` rather than
/// a `TypeError` is a decision rather than a shape.
library;

export 'src/key_value_shipment_cache.dart';
export 'src/manifest_barcode_resolver.dart';
export 'src/remote_barcode_resolver.dart';
export 'src/rest_shipment_gateway.dart';
export 'src/shipment_dto.dart';
export 'src/shipment_mapper.dart';
