import 'package:core_kernel/core_kernel.dart';
import 'package:shipments_api/shipments_api.dart';

import 'find_shipment.dart';

/// Turns a scan into the shipment it names.
///
/// Two steps through two ports, and the split matters: which adapter resolves
/// a barcode is an app-level decision — `app_courier` binds one backed by the
/// local manifest so a scan works in a warehouse doorway, `app_dispatcher`
/// binds the remote lookup — while reading the shipment afterwards is the same
/// everywhere. Folding the resolution into `ShipmentGateway` would make that
/// choice impossible without a second gateway.
final class ResolveBarcode
    implements UseCase<Barcode, Result<Shipment, ShipmentFailure>> {
  /// Creates the use case.
  const ResolveBarcode({
    required this._resolver,
    required this._findShipment,
  });

  final BarcodeResolverPort _resolver;
  final FindShipment _findShipment;

  @override
  Future<Result<Shipment, ShipmentFailure>> call(Barcode barcode) async {
    final resolved = await _resolver.resolve(barcode);

    return switch (resolved) {
      Failed(:final failure) => Failed(failure),
      Success(value: final id) => await _findShipment(id),
    };
  }
}
