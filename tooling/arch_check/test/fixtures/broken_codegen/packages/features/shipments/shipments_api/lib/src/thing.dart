/// The violation is in build.yaml and in the pubspec, not in this file.
abstract interface class ShipmentRepository {
  /// Loads one shipment.
  String byId(String id);
}
