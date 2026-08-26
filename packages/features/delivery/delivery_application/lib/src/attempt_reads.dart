import 'package:core_kernel/core_kernel.dart';
import 'package:delivery_api/delivery_api.dart';
import 'package:shipments_api/shipments_api.dart';

/// Reads what has already been tried at an address.
///
/// The only use case here that asks a question rather than changing something,
/// and the only one that goes to the gateway directly. Everything a courier
/// writes goes through the queue; what an operation reads back comes from the
/// server, because the answer to "what happened to this parcel" includes
/// visits made by somebody else's device.
///
/// It hands the gateway a raw identifier, which is the port's signature and
/// not an oversight: a driven port is implemented by an adapter, and an
/// adapter may see no foreign `_api`. Unwrapping the `ShipmentId` here is the
/// crossing being done by the layer that is allowed to do it.
final class AttemptReads
    implements
        UseCase<ShipmentId, Result<List<DeliveryAttempt>, DeliveryFailure>> {
  /// Creates the use case.
  const AttemptReads({required this._gateway});

  final DeliveryGateway _gateway;

  @override
  Future<Result<List<DeliveryAttempt>, DeliveryFailure>> call(
    ShipmentId shipment,
  ) => _gateway.attemptsFor(shipment.value);
}
