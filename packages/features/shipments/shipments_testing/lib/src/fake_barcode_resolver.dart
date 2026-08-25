import 'package:core_kernel/core_kernel.dart';
import 'package:shipments_api/shipments_api.dart';

/// A `BarcodeResolverPort` backed by a map a test fills in.
///
/// Separate from `InMemoryShipmentGateway` even though that fake can also
/// resolve, because the port is separate: an app that scans in a warehouse
/// doorway binds an offline resolver and an app on a desk binds the remote
/// lookup, and a test for either wants to say what the resolver knows without
/// building shipments to say it with.
final class FakeBarcodeResolver implements BarcodeResolverPort {
  final Map<String, ShipmentId> _known = {};

  /// Teaches the resolver that [barcode] names [id].
  void register(Barcode barcode, ShipmentId id) => _known[barcode.value] = id;

  /// Barcodes this resolver was asked about, in order.
  final List<Barcode> asked = [];

  @override
  Future<Result<ShipmentId, ShipmentFailure>> resolve(Barcode barcode) async {
    asked.add(barcode);

    final id = _known[barcode.value];
    if (id == null) return Failed(BarcodeNotRecognised(barcode.value));
    return Success(id);
  }
}
