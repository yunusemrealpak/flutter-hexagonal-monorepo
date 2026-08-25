/// A second port, so that the generated file beside it has something to
/// implement.
abstract interface class ShipmentCache {
  /// Reads one shipment.
  String? byId(String id);
}
