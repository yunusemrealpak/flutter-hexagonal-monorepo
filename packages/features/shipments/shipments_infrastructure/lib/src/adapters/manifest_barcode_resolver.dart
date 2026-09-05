import 'package:core_kernel/core_kernel.dart';
import 'package:shipments_api/shipments_api.dart';

/// Resolves a barcode against what this device already holds.
///
/// The offline half of the pair. It answers from the cache, so a courier can
/// scan in a warehouse doorway with no signal — and it answers
/// `BarcodeNotRecognised` for a parcel that is not on their manifest, which is
/// the right answer rather than a limitation: a courier scanning somebody
/// else's parcel wants to be told so, not to have it looked up.
final class ManifestBarcodeResolver implements BarcodeResolverPort {
  /// Creates the resolver over [cache] for [courierId]'s manifest.
  const ManifestBarcodeResolver({
    required this.cache,
    required this.courierId,
  });

  /// Where this device keeps what it has seen.
  final ShipmentCache cache;

  /// Whose manifest is being scanned against.
  final String courierId;

  @override
  Future<Result<ShipmentId, ShipmentFailure>> resolve(Barcode barcode) async {
    final manifest = await cache.manifestFor(courierId);

    return switch (manifest) {
      Failed(:final failure) => Failed(failure),
      Success(value: final rows) => _find(rows, barcode),
    };
  }

  Result<ShipmentId, ShipmentFailure> _find(
    List<ShipmentSummary> rows,
    Barcode barcode,
  ) {
    for (final row in rows) {
      if (row.barcode == barcode.value) return ShipmentId.parse(row.id);
    }
    return Failed(BarcodeNotRecognised(barcode.value));
  }
}
