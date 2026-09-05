import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';

import '../../entities/shipment.dart';
import '../../failures/shipment_failure.dart';
import '../../values/barcode.dart';
import '../../values/shipment_id.dart';
import '../../values/shipment_summary.dart';

/// What the rest of the product asks shipments to do.
///
/// One method per intention, rather than a single `advance(id, status)`. The
/// looser shape would let a caller construct the target state itself — proof
/// reference, timestamp and all — and the timestamp is exactly what a use case
/// takes from the `Clock` port so that it cannot be invented. A facade that
/// accepted a fully built state would hand that decision back to the caller,
/// and every test that wanted a delivery two hours ago could write one.
///
/// Both presentation packages drive this same interface. That is scenario 7:
/// `shipments_presentation_courier` calls [loadOnto] and [completeDelivery]
/// from a scan screen, `shipments_presentation_dispatcher` calls [assign] from
/// a table, and neither knows the other exists.
abstract interface class ShipmentsFacade {
  /// Loads one shipment by identifier.
  Future<Result<Shipment, ShipmentFailure>> byId(ShipmentId id);

  /// Loads one shipment by the number on its label.
  Future<Result<Shipment, ShipmentFailure>> byBarcode(Barcode barcode);

  /// One page of the rows a courier's stop list is drawn from.
  ///
  /// The page travels all the way out to the driving port rather than being
  /// hidden behind it. A facade that answered `List` while its gateway was
  /// paged would either fetch every page before returning — putting the
  /// unbounded read back, one layer up — or truncate silently at the first.
  /// Both are worse than a caller having to say how much it wants.
  Future<Result<PageOf<ShipmentSummary>, ShipmentFailure>> manifestFor(
    ActorId courier, {
    PageRequest page,
  });

  /// Puts a shipment on a courier's manifest.
  Future<Result<Shipment, ShipmentFailure>> assign({
    required ShipmentId id,
    required ActorId courier,
  });

  /// Records that a courier scanned a shipment into their vehicle.
  Future<Result<Shipment, ShipmentFailure>> loadOnto({
    required ShipmentId id,
    required ActorId courier,
  });

  /// Records that a courier left the depot with a shipment.
  Future<Result<Shipment, ShipmentFailure>> startDelivery({
    required ShipmentId id,
    required ActorId courier,
  });

  /// Records a hand-over, against a proof captured by `delivery`.
  Future<Result<Shipment, ShipmentFailure>> completeDelivery({
    required ShipmentId id,
    required String proofReference,
  });

  /// Records an attempt that did not result in a hand-over.
  Future<Result<Shipment, ShipmentFailure>> failDelivery({
    required ShipmentId id,
    required String reason,
  });

  /// Records that a shipment came back to the depot.
  Future<Result<Shipment, ShipmentFailure>> returnToDepot(ShipmentId id);

  /// Emits a shipment whenever one this device knows about changes.
  Stream<Shipment> changes();
}
