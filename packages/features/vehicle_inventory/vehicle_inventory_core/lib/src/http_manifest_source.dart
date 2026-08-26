import 'package:core_kernel/core_kernel.dart';
import 'package:http_dio/http_dio.dart';
import 'package:vehicle_inventory_api/vehicle_inventory_api.dart';

/// Asks the depot's backend what should be in a van.
///
/// The first of two answers to `ManifestSource`, and the reason the port is
/// worth having: `CachedManifestSource` is the second, and neither of them is
/// visible from a use case.
///
/// It reads identifiers out of the payload and hands them on as strings. It
/// does **not** build `ShipmentId`s, and not because it could not — a `_core`
/// package may see `shipments_api`. It does not because the port promises
/// strings, and an adapter that produced typed identifiers would be one that
/// could not move into an `_infrastructure` package the day this feature is
/// split.
final class HttpManifestSource implements ManifestSource {
  /// Creates the adapter over the transport it sends through.
  const HttpManifestSource({required this._transport});

  final HttpTransport _transport;

  @override
  Future<Result<List<String>, VehicleInventoryFailure>> manifestFor(
    String courierId,
  ) async {
    final response = await _transport.send(
      HttpRequest(
        method: HttpMethod.get,
        path: '/couriers/$courierId/manifest',
      ),
    );

    return switch (response) {
      Failed(:final failure) => Failed(_translate(failure)),
      Success(:final value) => _read(value.body),
    };
  }

  /// Reads the identifiers out of whatever came back.
  ///
  /// A body that is not a list of strings is `ManifestUnavailable` rather than
  /// an exception. Nothing throws across a port — invariant 1.2.9 — and a
  /// server that changed shape is precisely the case where a throw would reach
  /// a courier as a crash in a depot basement.
  Result<List<String>, VehicleInventoryFailure> _read(Object? body) {
    if (body is! List) {
      return const Failed(
        ManifestUnavailable(detail: 'the manifest was not a list'),
      );
    }

    final identifiers = <String>[];
    for (final element in body) {
      if (element is! String) {
        return const Failed(
          ManifestUnavailable(detail: 'a manifest entry was not an identifier'),
        );
      }
      identifiers.add(element);
    }
    return Success(identifiers);
  }

  /// Turns a transport failure into this feature's own.
  ///
  /// Every case collapses to `ManifestUnavailable`, and that is not laziness:
  /// there is exactly one thing a caller can do about any of them, which is
  /// fall back to the cached manifest. A feature that split them would be
  /// inviting a caller to treat a timeout differently from a 500 for no reason
  /// it could act on.
  VehicleInventoryFailure _translate(TransportFailure failure) =>
      ManifestUnavailable(detail: failure.toString());
}
