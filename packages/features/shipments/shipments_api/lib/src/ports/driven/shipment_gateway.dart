import 'package:core_kernel/core_kernel.dart';

import '../../entities/shipment.dart';
import '../../failures/shipment_failure.dart';
import '../../values/barcode.dart';
import '../../values/shipment_id.dart';
import '../../values/shipment_summary.dart';

/// The operation's record of its shipments, wherever that is kept.
///
/// A driven port. It speaks in shipments, never in requests: there is no URL,
/// no header, no status code in this file, and there cannot be —
/// `shipments_application`, which consumes it, may not depend on `platform/*`
/// at all. `RestShipmentGateway` in `shipments_infrastructure` answers it over
/// `HttpTransport`, and the retry policy that comes with doing so stays there,
/// where it is a technology decision rather than a business rule.
abstract interface class ShipmentGateway {
  /// Fetches one shipment.
  Future<Result<Shipment, ShipmentFailure>> byId(ShipmentId id);

  /// Fetches one page of a courier's manifest.
  ///
  /// **Paged rather than whole, and that is a contract decision rather than an
  /// optimisation.** A depot round is eleven hundred stops on a bad day; a
  /// port that answers `List` promises to hold all of them in memory, to
  /// serialise all of them over a van's connection, and to give a caller no
  /// way to ask for less. Walking that back later means changing this port,
  /// the use case, the controller and the screen at once, which is why it is
  /// decided here instead.
  ///
  /// **An implementation must serve the pages over a stable total order.**
  /// Without one, a row that moves between two requests is either served twice
  /// or not at all — a courier sent to the same door twice, or a parcel that
  /// never appears on their list. The order itself is the implementation's
  /// choice; that it does not change under paging is not.
  ///
  /// The cursor on the returned page is opaque and belongs to whoever produced
  /// it. Handing one implementation's cursor to another is meaningless, which
  /// is why `LoadManifest` will not fall back to the cache mid-sequence.
  Future<Result<PageOf<ShipmentSummary>, ShipmentFailure>> manifestFor(
    String courierId,
    PageRequest page,
  );

  /// Publishes a shipment's new state.
  ///
  /// Takes the whole shipment rather than a patch. The state machine has
  /// already decided what the shipment became; sending "what changed" would
  /// make the far side re-derive a decision this side already made, and the
  /// two would eventually disagree.
  Future<Result<Shipment, ShipmentFailure>> save(Shipment shipment);

  /// Resolves a barcode to the shipment it belongs to.
  Future<Result<ShipmentId, ShipmentFailure>> resolve(Barcode barcode);
}
