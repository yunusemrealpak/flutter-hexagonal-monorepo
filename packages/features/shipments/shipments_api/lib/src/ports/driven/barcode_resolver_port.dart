import 'package:core_kernel/core_kernel.dart';

import '../../failures/shipment_failure.dart';
import '../../values/barcode.dart';
import '../../values/shipment_id.dart';

/// Turns a scanned barcode into the shipment it names.
///
/// Narrow on purpose, and separate from `ShipmentGateway` even though a REST
/// adapter answers both. A scan happens in a warehouse doorway with no signal
/// as often as not, and the app that wants to resolve barcodes offline binds
/// an adapter backed by the local manifest, while the one on a desk binds the
/// remote lookup. Two adapters, one port, chosen by the composition root —
/// the same shape scenario 4 uses for route optimisation.
///
/// The `Port` suffix is unusual here: most ports in this workspace are named
/// for what they do (`ShipmentGateway`, `ShipmentCache`). This one keeps the
/// suffix the specification gives it, because `BarcodeResolver` alone reads
/// like a concrete class and this package must not contain one.
abstract interface class BarcodeResolverPort {
  /// Resolves [barcode], or reports that nothing in this operation carries it.
  Future<Result<ShipmentId, ShipmentFailure>> resolve(Barcode barcode);
}
