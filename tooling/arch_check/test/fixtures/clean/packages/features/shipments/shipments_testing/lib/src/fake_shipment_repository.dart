import 'package:core_kernel/core_kernel.dart';
import 'package:payments_api/payments_api.dart';
import 'package:shipments_api/shipments_api.dart';

/// A behavioural fake, holding a value declared by a foreign contract package.
final class FakeShipmentRepository implements ShipmentRepository {
  /// What the last lookup was worth.
  Money? collected;

  @override
  Future<Result<String, Object>> byId(String id) async => Success(id);
}
