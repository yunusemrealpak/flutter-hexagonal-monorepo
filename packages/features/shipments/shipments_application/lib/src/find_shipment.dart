import 'package:core_kernel/core_kernel.dart';
import 'package:shipments_api/shipments_api.dart';

/// Reads one shipment, preferring the network and falling back to the device.
///
/// The order is deliberate and it is the opposite of what "offline first"
/// usually means here. A courier acts on a shipment's *current* state — may I
/// deliver this? — and a stale answer from the cache would let them try a move
/// the operation has already made impossible. So the gateway is asked first,
/// and the cache answers only when the gateway could not.
///
/// The fallback is narrow on purpose: only `ShipmentsUnavailable` falls
/// through. A `ShipmentNotFound` from the gateway is an answer, not a failure
/// to answer, and serving a cached copy of a shipment the operation says does
/// not exist is how a cancelled parcel gets delivered anyway.
final class FindShipment
    implements UseCase<ShipmentId, Result<Shipment, ShipmentFailure>> {
  /// Creates the use case.
  const FindShipment({
    required this._gateway,
    required this._cache,
  });

  final ShipmentGateway _gateway;
  final ShipmentCache _cache;

  @override
  Future<Result<Shipment, ShipmentFailure>> call(ShipmentId id) async {
    final remote = await _gateway.byId(id);

    return switch (remote) {
      Success(value: final shipment) => await _cacheAndReturn(shipment),
      Failed(failure: ShipmentsUnavailable()) => await _fromCache(id, remote),
      Failed(:final failure) => Failed(failure),
    };
  }

  Future<Result<Shipment, ShipmentFailure>> _cacheAndReturn(
    Shipment shipment,
  ) async {
    await _cache.put(shipment);
    return Success(shipment);
  }

  Future<Result<Shipment, ShipmentFailure>> _fromCache(
    ShipmentId id,
    Result<Shipment, ShipmentFailure> remote,
  ) async {
    final cached = await _cache.byId(id);

    return switch (cached) {
      // A cache that is itself broken is not a better answer than the network
      // failure that sent us here, so the original one is what the caller
      // sees. Reporting the cache's failure would send somebody to look at
      // the wrong thing.
      Failed() => remote,
      Success(value: null) => remote,
      Success(value: final shipment?) => Success(shipment),
    };
  }
}
