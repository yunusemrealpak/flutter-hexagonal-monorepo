import 'package:core_kernel/core_kernel.dart';

/// What the feature needs from the outside world, in the product's words.
abstract interface class ShipmentRepository {
  /// Loads one shipment.
  Future<Result<String, Object>> byId(String id);
}
