/// The vehicle inventory use cases, the store that keeps a count, and two
/// answers to one manifest port.
///
/// **Scenario 4 at the smallest scale the workspace has it.**
/// `HttpManifestSource` asks the depot's backend; `CachedManifestSource` wraps
/// another source and remembers what it said. Neither is visible from a use
/// case — `StartCount` holds `ManifestSource` — and which one an app builds is
/// a composition-root decision. Here the two compose rather than compete,
/// which is the shape offline behaviour usually takes.
///
/// A depot basement has no signal. A feature that shipped only the HTTP
/// adapter would pass every test and fail every morning.
///
/// The halves, as everywhere in phase 6:
///
/// - `StartCount`, `RecordScan`, `CloseCount`, `FindOpenCount` and
///   `VehicleInventoryCoordinator` are the application half.
/// - `HttpManifestSource`, `CachedManifestSource`, `KeyValueLoadCountStore`
///   and `LoadCountDto` are the infrastructure half. They import no use case,
///   and no use case imports them.
library;

export 'src/cached_manifest_source.dart';
export 'src/close_count.dart';
export 'src/find_open_count.dart';
export 'src/http_manifest_source.dart';
export 'src/key_value_load_count_store.dart';
export 'src/load_count_dto.dart';
export 'src/record_scan.dart';
export 'src/start_count.dart';
export 'src/vehicle_inventory_coordinator.dart';
