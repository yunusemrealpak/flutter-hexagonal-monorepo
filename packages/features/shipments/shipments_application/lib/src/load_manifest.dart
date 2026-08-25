import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';
import 'package:shipments_api/shipments_api.dart';

/// The rows a courier's stop list is drawn from.
///
/// Gateway first, cache second, and only when the gateway could not be
/// reached — the same rule as `FindShipment`, for the same reason.
///
/// **What the cache can answer with is a subset.** It holds the shipments this
/// device has actually handled, so an offline manifest is what the courier had
/// in hand rather than what the operation assigned them this morning. Closing
/// that gap needs a sync that pulls a manifest ahead of time and an outbox
/// that carries the moves back, which is `sync`'s job in phase 5. Until then
/// the shortfall is stated here rather than hidden behind an answer that looks
/// complete.
final class LoadManifest
    implements
        UseCase<ActorId, Result<List<ShipmentSummary>, ShipmentFailure>> {
  /// Creates the use case.
  const LoadManifest({
    required this._gateway,
    required this._cache,
  });

  final ShipmentGateway _gateway;
  final ShipmentCache _cache;

  @override
  Future<Result<List<ShipmentSummary>, ShipmentFailure>> call(
    ActorId courier,
  ) async {
    final remote = await _gateway.manifestFor(courier.value);

    return switch (remote) {
      Success() => remote,
      Failed(failure: ShipmentsUnavailable()) => await _fromCache(
        courier,
        remote,
      ),
      Failed() => remote,
    };
  }

  Future<Result<List<ShipmentSummary>, ShipmentFailure>> _fromCache(
    ActorId courier,
    Result<List<ShipmentSummary>, ShipmentFailure> remote,
  ) async {
    final cached = await _cache.manifestFor(courier.value);
    return cached.isSuccess ? cached : remote;
  }
}
