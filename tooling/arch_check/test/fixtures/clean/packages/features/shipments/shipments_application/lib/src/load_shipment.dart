import 'package:core_kernel/core_kernel.dart';
import 'package:shipments_api/shipments_api.dart';

/// One product intention, with every collaborator arriving by constructor.
final class LoadShipment {
  /// Creates the use case.
  const LoadShipment(this._repository);

  final ShipmentRepository _repository;

  /// Runs it.
  Future<Result<String, Object>> call(String id) => _repository.byId(id);
}
