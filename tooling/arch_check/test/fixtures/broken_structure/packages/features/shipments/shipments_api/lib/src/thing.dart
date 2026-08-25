import 'package:core_kernel/src/thing.dart';

/// A port, declared the way every port in this workspace is declared.
abstract interface class ShipmentRepository {
  /// Loads one shipment.
  String byId(String id);
}

/// S8: the implementation of that port, inside the contract package.
final class InMemoryShipmentRepository implements ShipmentRepository {
  @override
  String byId(String id) => kernelThing;
}

/// S8 again, by name this time: a concrete class that reads as an
/// implementation even though it implements nothing declared here.
final class ShipmentHttpAdapter {
  /// Creates it.
  const ShipmentHttpAdapter();
}
