/// The location contract, its geolocator adapter, and its fake.
///
/// `LocationSource` is a technology contract and lives here for the same
/// reason `HttpTransport` lives in `http_dio`: nothing in the product asks for
/// "a GPS fix". `delivery` asks whether a courier is at the consignee's
/// address, `routing` asks how far along a route they are — ports in those
/// features' own `_api` packages, answered by their `_infrastructure` using
/// this.
///
/// `GeoFix` is deliberately not a domain type either. The features that need
/// coordinates declare their own, with their own invariants, and map this into
/// them — the same DTO-to-entity discipline rule 1.2.10 asks for at every
/// other boundary.
///
/// The adapter asks for permission through `core_ports.PermissionRequester`
/// rather than through geolocator's own permission API, which is worth
/// noticing: the real permission adapter lives in `device_permissions`, and a
/// direct dependency on it would be the `platform/*` -> `platform/*` edge the
/// constitution forbids. Depending on the port instead is what obeying that
/// rule looks like when two platform packages genuinely need each other.
library;

export 'src/fake_location_source.dart';
export 'src/fix_accuracy.dart';
export 'src/geo_fix.dart';
export 'src/geolocator_location_source.dart';
export 'src/location_failure.dart';
export 'src/location_source.dart';
