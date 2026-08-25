import 'package:core_kernel/core_kernel.dart';
import 'package:shipments_api/shipments_api.dart';

/// A `ShipmentCache` that really caches, in a map.
///
/// Behaviourally distinct from `InMemoryShipmentGateway` in the one way that
/// matters: a miss is `Success(null)`, not a failure. An empty cache is the
/// ordinary state of a fresh install, and a fake that failed on a miss would
/// let a caller ship a "no signal" message where "we have not seen this yet"
/// belongs.
final class InMemoryShipmentCache implements ShipmentCache {
  final Map<String, Shipment> _byId = {};

  final List<ShipmentFailure> _queuedFailures = [];

  /// Makes the next call return [failure]. See the note on the gateway fake.
  void failNextWith(ShipmentFailure failure) => _queuedFailures.add(failure);

  /// How many shipments this cache is holding.
  int get length => _byId.length;

  @override
  Future<Result<Shipment?, ShipmentFailure>> byId(ShipmentId id) async {
    final failure = _takeFailure();
    if (failure != null) return Failed(failure);

    return Success(_byId[id.value]);
  }

  @override
  Future<Result<List<ShipmentSummary>, ShipmentFailure>> manifestFor(
    String courierId,
  ) async {
    final failure = _takeFailure();
    if (failure != null) return Failed(failure);

    final rows = _byId.values
        .where((shipment) => shipment.status.courier?.value == courierId)
        .map(
          (shipment) => ShipmentSummary(
            id: shipment.id.value,
            barcode: shipment.barcode.value,
            status: shipment.status,
            consigneeName: shipment.consignee.name,
            address: shipment.consignee.address.formatted,
          ),
        )
        .toList();
    return Success(rows);
  }

  @override
  Future<Result<void, ShipmentFailure>> put(Shipment shipment) async {
    final failure = _takeFailure();
    if (failure != null) return Failed(failure);

    _byId[shipment.id.value] = shipment;
    return const Success(null);
  }

  @override
  Future<Result<void, ShipmentFailure>> clear() async {
    final failure = _takeFailure();
    if (failure != null) return Failed(failure);

    _byId.clear();
    return const Success(null);
  }

  ShipmentFailure? _takeFailure() =>
      _queuedFailures.isEmpty ? null : _queuedFailures.removeAt(0);
}
