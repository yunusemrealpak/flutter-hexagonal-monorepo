import 'package:core_kernel/core_kernel.dart';

import '../../entities/shipment.dart';
import '../../failures/shipment_failure.dart';
import '../../values/shipment_id.dart';
import '../../values/shipment_summary.dart';

/// What the device knows about shipments when the network does not answer.
///
/// A second driven port rather than a flag on `ShipmentGateway`, because they
/// fail differently and a caller has to be able to tell. A gateway that cannot
/// be reached is a shipment whose state is unknown; a cache that has nothing
/// is a shipment this device has not seen. Merging them would make "no signal"
/// and "not yours" the same answer on a courier's stop list.
///
/// Reads return `Shipment?` rather than failing on a miss: an empty cache is
/// the ordinary state of a fresh install, not something that went wrong.
abstract interface class ShipmentCache {
  /// Reads a shipment, or `null` when this device has not seen it.
  Future<Result<Shipment?, ShipmentFailure>> byId(ShipmentId id);

  /// Reads a courier's manifest as this device last saw it.
  ///
  /// **Not paged, where `ShipmentGateway.manifestFor` is.** The two are
  /// bounded by different things: the gateway answers what the operation
  /// assigned, which is unbounded from this device's point of view, and this
  /// answers what this device has actually handled, which is one courier's
  /// working set. Paging it would add a cursor no caller could use — the fall
  /// back to the cache happens when the network stopped answering, and a
  /// cursor from the gateway means nothing here.
  Future<Result<List<ShipmentSummary>, ShipmentFailure>> manifestFor(
    String courierId,
  );

  /// Stores a shipment, replacing what was there.
  Future<Result<void, ShipmentFailure>> put(Shipment shipment);

  /// Forgets everything about the shipments this device holds.
  Future<Result<void, ShipmentFailure>> clear();
}
