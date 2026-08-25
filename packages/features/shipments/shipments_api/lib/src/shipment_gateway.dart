import 'package:core_kernel/core_kernel.dart';

import 'barcode.dart';
import 'shipment.dart';
import 'shipment_failure.dart';
import 'shipment_id.dart';
import 'shipment_summary.dart';

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

  /// Fetches the rows of a courier's manifest.
  Future<Result<List<ShipmentSummary>, ShipmentFailure>> manifestFor(
    String courierId,
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
