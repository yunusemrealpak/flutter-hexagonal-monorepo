import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';
import 'package:shipments_api/shipments_api.dart';

/// One page of the rows a courier's stop list is drawn from.
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
///
/// **Only the first page falls back, and that is not a shortcut.** A cursor is
/// opaque to everyone but the source that produced it, so the gateway's cursor
/// says nothing to the cache. A fallback part-way through a walk would either
/// have to start the cache from the beginning — serving rows the courier has
/// already scrolled past as if they were new — or guess at a translation
/// between two orderings nobody promised to keep in step. Refusing is the only
/// answer that cannot silently duplicate or skip a parcel, and the caller
/// already knows how to show a failure.
final class LoadManifest
    implements
        UseCase<
          ({ActorId courier, PageRequest page}),
          Result<PageOf<ShipmentSummary>, ShipmentFailure>
        > {
  /// Creates the use case.
  const LoadManifest({
    required this._gateway,
    required this._cache,
  });

  final ShipmentGateway _gateway;
  final ShipmentCache _cache;

  @override
  Future<Result<PageOf<ShipmentSummary>, ShipmentFailure>> call(
    ({ActorId courier, PageRequest page}) query,
  ) async {
    final remote = await _gateway.manifestFor(query.courier.value, query.page);

    return switch (remote) {
      Success() => remote,
      Failed(failure: ShipmentsUnavailable()) when query.page.after == null =>
        await _fromCache(query.courier, remote),
      Failed() => remote,
    };
  }

  /// What this device holds, as a single page that ends there.
  ///
  /// No cursor, because there is nothing behind it: the cache is not paged and
  /// what it has is what the courier handled. Answering one would invite a
  /// caller to ask for a second page the cache has no way to produce.
  Future<Result<PageOf<ShipmentSummary>, ShipmentFailure>> _fromCache(
    ActorId courier,
    Result<PageOf<ShipmentSummary>, ShipmentFailure> remote,
  ) async {
    final cached = await _cache.manifestFor(courier.value);
    return switch (cached) {
      Success(value: final rows) => Success(PageOf(items: rows)),
      Failed() => remote,
    };
  }
}
