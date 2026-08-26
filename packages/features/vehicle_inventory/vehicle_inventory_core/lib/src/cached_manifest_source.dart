import 'dart:convert';

import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:vehicle_inventory_api/vehicle_inventory_api.dart';

/// Answers the manifest port from the last manifest that worked.
///
/// The second answer to `ManifestSource`, and a decorator rather than a
/// replacement: it holds another source, asks it first, and remembers what it
/// said. This is scenario 4 at the smallest scale the workspace has it —
/// **one port, two implementations, and a composition root that decides which
/// one an app gets** — with the wrinkle that here the two compose.
///
/// **A depot basement has no signal.** That is the whole reason this exists:
/// the manifest is fetched over the network and the count happens where the
/// network is not. A feature that only had `HttpManifestSource` would work in
/// every test and fail every morning.
///
/// The fallback is silent by design. A courier who cannot start counting
/// because the server is slow is a courier standing next to a van they could
/// be loading; the staleness that costs is a manifest a few hours old, and the
/// count itself is what discovers the difference.
final class CachedManifestSource implements ManifestSource {
  /// Creates the decorator over another source, caching in a key-value store.
  const CachedManifestSource({required this._upstream, required this._store});

  final ManifestSource _upstream;
  final KeyValueStore _store;

  /// The prefix every key this adapter writes carries.
  static const keyPrefix = 'vehicle_inventory.manifest.';

  @override
  Future<Result<List<String>, VehicleInventoryFailure>> manifestFor(
    String courierId,
  ) async {
    final fresh = await _upstream.manifestFor(courierId);
    if (fresh case Success(:final value)) {
      // The write is not awaited for its result: a manifest that arrived is
      // still the answer even if the cache could not take it. Failing the call
      // because the *cache* failed would turn a working morning into a broken
      // one.
      await _remember(courierId, value);
      return fresh;
    }

    final cached = await _cached(courierId);
    return switch (cached) {
      Success(value: final manifest?) => Success(manifest),
      // Nothing upstream and nothing cached. The upstream failure is the one
      // worth reporting: it says why, and the empty cache says nothing.
      _ => fresh,
    };
  }

  Future<void> _remember(String courierId, List<String> manifest) async {
    await _store.write('$keyPrefix$courierId', jsonEncode(manifest));
  }

  Future<Result<List<String>?, VehicleInventoryFailure>> _cached(
    String courierId,
  ) async {
    final raw = await _store.read('$keyPrefix$courierId');
    if (raw case Failed()) {
      return const Success(null);
    }

    final text = (raw as Success<String?, StoreFailure>).value;
    if (text == null) {
      return const Success(null);
    }

    try {
      final decoded = jsonDecode(text);
      if (decoded is! List) {
        return const Success(null);
      }
      final identifiers = <String>[];
      for (final element in decoded) {
        if (element is! String) {
          return const Success(null);
        }
        identifiers.add(element);
      }
      return Success(identifiers);
    } on FormatException {
      return const Success(null);
    }
  }
}
