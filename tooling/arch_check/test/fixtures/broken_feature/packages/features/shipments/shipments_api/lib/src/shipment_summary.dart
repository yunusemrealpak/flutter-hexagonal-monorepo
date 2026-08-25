/// What another feature is allowed to know about a shipment.
abstract interface class ShipmentSummary {
  /// The shipment's identifier.
  String get id;

  /// Whether it has been delivered.
  bool get isDelivered;
}
