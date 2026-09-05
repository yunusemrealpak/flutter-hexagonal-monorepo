/// The vehicle inventory contract: what should be in the van, what was
/// actually scanned, and the difference somebody has to explain.
///
/// **The discrepancy is derived, never stored.** `LoadCount.missing` and
/// `LoadCount.unexpected` are set arithmetic over the manifest and the scans.
/// Storing them alongside would make a state where the three disagree
/// representable, and that is the state a bug produces in the record somebody
/// uses to argue about a lost parcel.
///
/// **A count closes while it disagrees.** That is what it is for. A rule that
/// refused to close an incomplete count would leave couriers at the depot with
/// a screen they cannot dismiss, and the discrepancy would travel by message
/// instead of by record.
///
/// **`ManifestSource` is not `ShipmentsFacade`.** Shipments can already say
/// what is on a courier's manifest, and consuming that would drag
/// `ShipmentSummary` — an address, a consignee, a status — into a feature
/// whose whole job is counting. This port answers with raw identifiers, and an
/// app's composition root is free to implement it over that facade.
library;

export 'src/entities/load_count.dart';
export 'src/failures/vehicle_inventory_failure.dart';
export 'src/ports/driven/load_count_store.dart';
export 'src/ports/driven/manifest_source.dart';
export 'src/ports/driving/vehicle_inventory_facade.dart';
export 'src/values/load_count_id.dart';
export 'src/values/load_direction.dart';
