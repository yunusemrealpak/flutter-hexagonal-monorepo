import 'package:core_kernel/core_kernel.dart';
import 'package:shipments_api/shipments_api.dart';

import 'rest_shipment_gateway.dart';

/// Resolves a barcode by asking the operation.
///
/// One of two adapters for `BarcodeResolverPort` in this package, and the pair
/// is the small version of scenario 4: `app_dispatcher` binds this one,
/// `app_courier` binds `ManifestBarcodeResolver`, and the use case above them
/// does not change a line. A scan on a desk should hit the source of truth; a
/// scan in a warehouse doorway with no signal should still work.
final class RemoteBarcodeResolver implements BarcodeResolverPort {
  /// Creates the resolver over [gateway].
  const RemoteBarcodeResolver({required this.gateway});

  /// The gateway the lookup goes through.
  final RestShipmentGateway gateway;

  @override
  Future<Result<ShipmentId, ShipmentFailure>> resolve(Barcode barcode) =>
      gateway.resolve(barcode);
}
